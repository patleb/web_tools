#define NO_POINT -1

namespace GDAL {
  class Raster : public Base {
    public:

    struct Transform {
      Vector  mesh;
      size_t  width, height; // always >= to the original grid
      double  x0, y0;
      double  dx, dy;
      ssize_t rx, ry; // always >= 1

      auto _mesh_() const { return mesh; }
      auto shape()  const { return Vsize_t{ height, width }; }

      string cache_key(const Raster & raster) const {
        return raster.cache_key()
          + std::format(":{}:{}:{}:{}:{}:{}:{}:{}:{}", width, height, x0, y0, dx, dy, rx, ry, reinterpret_cast< std::uintptr_t >(mesh.srs));
      }
    };

    Tensor::NType z;
    Tensor::Base & tensor; // stored as [y, x]
    size_t width, height;
    double x0 = Float::nan, y0 = Float::nan;
    double dx = Float::nan, dy = Float::nan;

    Raster(Tensor::Base & z, Tensor::Type type, const Vdouble & x01_y01, const Ostring & proj = nil):
      Base::Base(proj.value_or("4326")),
      z(Tensor::cast(z, type)),
      tensor(Tensor::cast(this->z)) {
      if (z.rank != 2)         throw RuntimeError("invalid z dimensions");
      this->width = z.shape[1];   this->height = z.shape[0];
      if (width < 2)           throw RuntimeError("invalid x axis size");
      if (height < 2)          throw RuntimeError("invalid y axis size");
      if (x01_y01.size() != 4) throw RuntimeError("invalid x01_y01 size");
      this->x0 = x01_y01[0];      this->y0 = x01_y01[2];
      this->dx = x01_y01[1] - x0; this->dy = x01_y01[3] - y0;
      if (dx == 0 || dy == 0)  throw RuntimeError("invalid x01_y01 delta");
      auto orientation = this->orientation();
      if (orientation[0] * std::abs(dx) != dx) throw RuntimeError("invalid x axis orientation");
      if (orientation[1] * std::abs(dy) != dy) throw RuntimeError("invalid y axis orientation");
    }

    Raster(const Raster & raster):
      Base::Base(raster.srs),
      z(raster.z),
      tensor(Tensor::cast(this->z)),
      width(raster.width), height(raster.height),
      x0(raster.x0), y0(raster.y0),
      dx(raster.dx), dy(raster.dy) {
    }

    Raster & operator=(const Raster & raster) = delete;

    auto fill_value() const { return tensor.nodata_value(); }
    auto shape()      const { return tensor.shape; }
    auto type()       const { return tensor.type; }

    Vdouble x() const {
      Vdouble x(width);
      double xi = x0;
      for (size_t i = 0; i < width; ++i, xi += dx) x[i] = xi;
      return x;
    }

    Vdouble y() const {
      Vdouble y(height);
      double yi = y0;
      for (size_t i = 0; i < height; ++i, yi += dy) y[i] = yi;
      return y;
    }

    auto _z_() const { return z; }

    Raster reproject(const string & proj, const GType & fill_value = none, Obool memoize = nil) const {
      auto tf = transform_for(proj, memoize);
      auto nearest = nearest_for(tf, memoize);
      auto & width = tf.width, & height = tf.height;
      auto & x0 = tf.x0,       & y0 = tf.y0;
      auto & dx = tf.dx,       & dy = tf.dy;
      switch (type()) {
      <%- template[:numeric].each do |TENSOR, T| -%>
      case Tensor::Type::TENSOR: {
        auto src_nodata = *reinterpret_cast< const T * >(tensor.nodata);
        auto dst_nodata = is_none(fill_value) ? src_nodata : g_cast< T >(fill_value);
        auto src_data = reinterpret_cast< const T * >(tensor.data());
        auto dst_z = Tensor::build(type(), { height, width }, g_cast(dst_nodata));
        auto & dst_tensor = Tensor::cast(dst_z);
        auto dst_data = reinterpret_cast< T * >(dst_tensor.data());
        bool src_isnan_nodata = std::isnan(src_nodata);
        for (size_t j = 0; j < height; ++j) {
          for (size_t i = 0; i < width; ++i, ++dst_data) {
            auto point = nearest[j][i];
            if (point == NO_POINT) {
              *dst_data = dst_nodata;
            } else {
              auto value = src_data[point];
              if (src_isnan_nodata) {
                *dst_data = std::isnan(value) ? dst_nodata : value;
              } else {
                *dst_data = (value == src_nodata) ? dst_nodata : value;
              }
            }
          }
        }
        return Raster(dst_tensor, type(), { x0, x0 + dx, y0, y0 + dy }, proj);
      }
      <%- end -%>
      default:
        throw RuntimeError("invalid Tensor::Type");
      }
    }

    Raster::Transform transform_for(const string & proj, Obool memoize = nil) const {
      if (memoize.value_or(false)) return cached_transform_for(proj);
      size_t total = width * height;
      Transform tf;
      auto grid = Vector(Vdouble(total), Vdouble(total), srs);
      auto & x = grid.x, & y = grid.y;
      size_t point = 0;
      double xi, yj = y0;
      for (size_t j = 0; j < height; ++j, yj += dy) {
        xi = x0;
        for (size_t i = 0; i < width; ++i, ++point, xi += dx) {
          x[point] = xi;
          y[point] = yj;
        }
      }
      tf.mesh = grid.reproject(proj);
      auto & dst_x = tf.mesh.x, & dst_y = tf.mesh.y;
      double  x_min = Float::inf,  x_max = -Float::inf,  y_min = Float::inf,  y_max = -Float::inf;
      double dx_min = Float::inf, dx_max = -Float::inf, dy_min = Float::inf, dy_max = -Float::inf;
      double x_prev; Vdouble y_prev(width);
      double dxi, dyj;
      point = 0;
      for (size_t j = 0; j < height; ++j) {
        for (size_t i = 0; i < width; ++i, ++point) {
          xi = dst_x[point]; yj = dst_y[point];
          if (xi < x_min) x_min = xi; if (xi > x_max) x_max = xi;
          if (yj < y_min) y_min = yj; if (yj > y_max) y_max = yj;
          if (i && std::signbit(xi) == std::signbit(x_prev)) {
            dxi = std::abs(xi - x_prev);
            if (dxi < dx_min) dx_min = dxi; if (dxi > dx_max) dx_max = dxi;
          }
          if (j && std::signbit(yj) == std::signbit(y_prev[i])) {
            dyj = std::abs(yj - y_prev[i]);
            if (dyj < dy_min) dy_min = dyj; if (dyj > dy_max) dy_max = dyj;
          }
          x_prev = xi; y_prev[i] = yj;
        }
      }
      tf.width  = width;
      tf.height = height;
      dx_min = (x_max - x_min) / (width - 1);
      dy_min = (y_max - y_min) / (height - 1);
      tf.rx = std::ceil(dx_max / dx_min);
      tf.ry = std::ceil(dy_max / dy_min);
      auto orientation = _orientation_(proj);
      if (orientation[0] < 0) { auto tmp = x_min; x_min = x_max; x_max = tmp; }
      if (orientation[1] < 0) { auto tmp = y_min; y_min = y_max; y_max = tmp; }
      tf.x0 = x_min; tf.y0 = y_min;
      tf.dx = (x_max - x_min) / (tf.width - 1);
      tf.dy = (y_max - y_min) / (tf.height - 1);
      return tf;
    }

    string cache_key() const {
      return std::format("{}:{}:{}:{}:{}:{}:{}", width, height, x0, y0, dx, dy, reinterpret_cast< std::uintptr_t >(srs));
    }

    private:

    auto cache_key_for(const string & proj) const {
      return cache_key() + std::format(":{}", reinterpret_cast< std::uintptr_t >(srs_for(proj)));
    }

    Raster::Transform cached_transform_for(const string & proj) const {
      static std::unordered_map< string, Transform > cache;
      string key = cache_key_for(proj);
      if (!cache.contains(key)) cache[key] = transform_for(proj);
      return cache[key];
    }

    vector< Vssize_t > nearest_for(const Transform & tf, Obool memoize = nil) const {
      if (memoize.value_or(false)) return cached_nearest_for(tf);
      auto & width = tf.width, & height = tf.height;
      auto & x  = tf.mesh.x, & y  = tf.mesh.y;
      auto & x0 = tf.x0,     & y0 = tf.y0;
      auto & dx = tf.dx,     & dy = tf.dy;
      auto & rx = tf.rx,     & ry = tf.ry;
      auto max_rx = std::abs(dx * rx);
      auto max_ry = std::abs(dy * ry);
      auto & total = tf.mesh.size;
      vector< vector< std::unordered_set< size_t >>> mesh_points(height);
      ssize_t i, j;
      for (i = 0; i < height; ++i) mesh_points[i] = vector< std::unordered_set< size_t >>(width);
      for (size_t point = 0; point < total; ++point) {
        j = std::round((y[point] - y0) / dy);
        i = std::round((x[point] - x0) / dx);
        mesh_points[j][i].insert(point);
      }
      ssize_t box_i, box_j;
      vector< Vssize_t > nearest(height);
      for (i = 0; i < height; ++i) nearest[i] = Vssize_t(width);
      double yj = y0;
      for (j = 0; j < height; ++j, yj += dy) {
        double xi = x0;
        for (i = 0; i < width; ++i, xi += dx) {
          std::unordered_set< size_t > points;
          for (box_j = j - ry; box_j <= j + ry; ++box_j) {
            if (box_j < 0 || box_j >= height) continue;
            for (box_i = i - rx; box_i <= i + rx; ++box_i) {
              if (box_i < 0 || box_i >= width) continue;
              auto & box_points = mesh_points[box_j][box_i];
              points.insert(box_points.begin(), box_points.end());
            }
          }
          std::map< double, std::set< size_t >> distances;
          double dist_x, dist_y, dist;
          for (auto && point : points) {
            if ((dist_x = std::abs(x[point] - xi)) > max_rx) continue;
            if ((dist_y = std::abs(y[point] - yj)) > max_ry) continue;
            dist = dist_x * dist_x + dist_y * dist_y;
            distances[dist].insert(point);
          }
          if (distances.empty()) {
            nearest[j][i] = NO_POINT;
          } else {
            nearest[j][i] = *(distances.begin()->second.begin());
          }
        }
      }
      return nearest;
    }

    vector< Vssize_t > & cached_nearest_for(const Transform & tf) const {
      static std::unordered_map< string, vector< Vssize_t >> cache;
      string key = tf.cache_key(*this);
      if (!cache.contains(key)) cache[key] = nearest_for(tf);
      return cache[key];
    }
  };
}
