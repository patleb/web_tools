#define NO_POINT -1

namespace GDAL {
  class Raster : public Base {
    public:

    struct Transform {
      Vector mesh;
      size_t width, height; // always >= to the original grid
      double x0, y0;
      double dx, dy;
      size_t rx, ry; // always >= 1

      auto shape() const {
        return vector< size_t >{ height, width };
      }

      auto cache_key(const Raster & raster) const {
        return raster.cache_key()
          + std::format(":{}:{}:{}:{}:{}:{}:{}:{}:{}", width, height, x0, y0, dx, dy, rx, ry, reinterpret_cast< std::uintptr_t >(mesh.srs));
      }
    };

    Numo::NType values;
    Numo::NArray & data; // stored as [y, x]
    double nodata = C::Nil;
    size_t width;
    size_t height;
    double x0 = C::NaN;
    double y0 = C::NaN;
    double dx = C::NaN;
    double dy = C::NaN;

    using Base::Base;

    Raster(Numo::NArray z, Numo::Type type_id, vector < double > x01_y01, string proj = "4326", double nodata = C::Nil):
      Base(proj),
      values(Numo::cast(z, type_id)),
      data(Numo::cast(this->values)),
      nodata(nodata) {
      auto shape = z.shape();
      if (shape.size() != 2)   throw RuntimeError("invalid z dimensions");
      this->width = shape[1];
      this->height = shape[0];
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

    auto shape() {
      return data.shape();
    }

    auto type() {
      return data.type_id();
    }

    auto x() const {
      vector< double > x(width);
      double xi = x0;
      for (size_t i = 0; i < width; ++i, xi += dx) x[i] = xi;
      return x;
    }

    auto y() const {
      vector<double> y(height);
      double yi = y0;
      for (size_t i = 0; i < height; ++i, yi += dy) y[i] = yi;
      return y;
    }

    auto z() const {
      return values;
    }

    auto reproject(string proj, double nodata = C::Nil, bool compact = false, bool memoize = false) {
      nodata = (nodata == C::Nil) ? this->nodata : nodata;
      auto tf = transform_for(proj, compact, memoize);
      auto nearest = nearest_for(tf, memoize);
      auto & width = tf.width, & height = tf.height;
      auto & x0 = tf.x0,       & y0 = tf.y0;
      auto & dx = tf.dx,       & dy = tf.dy;
      auto dst_values = Numo::build(type(), { height, width });
      auto & dst_data = Numo::cast(dst_values);
      switch (type()) {
      <%- compile_vars[:numeric_types].each do |numo_type, type| -%>
      case Numo::Type::<%= numo_type %>: {
        auto src_z = reinterpret_cast< const <%= type %> * >(data.read_ptr());
        auto dst_z = reinterpret_cast< <%= type %> * >(dst_data.write_ptr());
        double yj = y0;
        for (size_t j = 0; j < height; ++j) {
          double xi = x0;
          for (size_t i = 0; i < width; ++i, ++dst_z) {
            auto point = nearest[j][i];
            if (point == NO_POINT) {
              *dst_z = nodata;
            } else {
              <%= type %> value = src_z[point];
              *dst_z = (value == this->nodata) ? nodata : value;
            }
          }
        }
        break;
      }
      <%- end -%>
      default:
        throw RuntimeError("invalid Numo::Type");
      }
      return Raster(dst_data, type(), { x0, x0 + dx, y0, y0 + dy }, proj, nodata);
    }

    Transform transform_for(const string & proj, bool compact = false, bool memoize = false) const {
      if (memoize) return cached_transform_for(proj, compact);
      size_t total = width * height;
      Transform tf;
      auto grid = Vector(vector< double >(total), vector< double >(total), srs);
      auto & x = grid.lon, & y = grid.lat;
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
      auto & dst_x = tf.mesh.lon, & dst_y = tf.mesh.lat;
      double  x_min = C::Inf,  x_max = -C::Inf,  y_min = C::Inf,  y_max = -C::Inf;
      double dx_min = C::Inf, dx_max = -C::Inf, dy_min = C::Inf, dy_max = -C::Inf;
      double x_prev; vector< double > y_prev(width);
      double dxi, dyj;
      point = 0;
      for (size_t j = 0; j < height; ++j) {
        for (size_t i = 0; i < width; ++i, ++point) {
          xi = dst_x[point]; yj = dst_y[point];
          if (xi < x_min) x_min = xi; if (xi > x_max) x_max = xi;
          if (yj < y_min) y_min = yj; if (yj > y_max) y_max = yj;
          if (i > 0) {
            dxi = std::abs(xi - x_prev);
            if (dxi < dx_min) dx_min = dxi; if (dxi > dx_max) dx_max = dxi;
          }
          if (j > 0) {
            dyj = std::abs(yj - y_prev[i]);
            if (dyj < dy_min) dy_min = dyj; if (dyj > dy_max) dy_max = dyj;
          }
          x_prev = xi; y_prev[i] = yj;
        }
      }
      if (compact) {
        tf.width  = width;
        tf.height = height;
        dx_min = (x_max - x_min) / (width - 1);
        dy_min = (y_max - y_min) / (height - 1);
      } else {
        // NOTE std::floor --> a bigger width would mean a smaller dx_min and rx could become too small
        tf.width  = std::floor((x_max - x_min) / dx_min) + 1;
        tf.height = std::floor((y_max - y_min) / dy_min) + 1;
        if (tf.width < width || tf.height < height) throw RuntimeError("resolution error");
      }
      tf.rx = std::ceil(dx_max / dx_min);
      tf.ry = std::ceil(dy_max / dy_min);
      auto orientation = orientation_for(proj);
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

    auto cache_key_for(const string & proj, bool compact) const {
      return cache_key() + std::format(":{}:{}", reinterpret_cast< std::uintptr_t >(srs_for(proj)), compact);
    }

    Transform cached_transform_for(const string & proj, bool compact = false) const {
      static std::unordered_map< string, Transform > cache;
      string key = cache_key_for(proj, compact);
      if (!cache.contains(key)) cache[key] = transform_for(proj, compact);
      return cache[key];
    }

    vector< vector< ssize_t >> nearest_for(const Transform & tf, bool memoize = false) const {
      if (memoize) return cached_nearest_for(tf);
      auto & width = tf.width, & height = tf.height;
      auto & x  = tf.mesh.lon, & y  = tf.mesh.lat;
      auto & x0 = tf.x0,       & y0 = tf.y0;
      auto & dx = tf.dx,       & dy = tf.dy;
      auto & rx = tf.rx,       & ry = tf.ry;
      auto max_rx = std::abs(rx * dx);
      auto max_ry = std::abs(ry * dy);
      auto & total = tf.mesh.size;
      vector< vector< std::unordered_set< size_t >>> mesh_points(height);
      size_t i, j;
      for (i = 0; i < height; ++i) mesh_points[i] = vector< std::unordered_set< size_t >>(width);
      for (size_t point = 0; point < total; ++point) {
        j = std::round((y[point] - y0) / dy);
        i = std::round((x[point] - x0) / dx);
        mesh_points[j][i].insert(point);
      }
      size_t box_i, box_j;
      vector< vector< ssize_t >> nearest(height);
      for (i = 0; i < height; ++i) nearest[i] = vector< ssize_t >(width);
      double yj = y0;
      for (j = 0; j < height; ++j) {
        double xi = x0;
        for (i = 0; i < width; ++i) {
          std::unordered_set< size_t > points;
          for (box_j = j - ry; box_j <= j + ry; ++box_j) {
            if (box_j < 0 || box_j >= height) continue;
            for (box_i = i - rx; box_i <= i + rx; ++box_i) {
              if (box_i < 0 || box_i >= width) continue;
              points.merge(mesh_points[box_j][box_i]);
            }
          }
          std::map< double, std::set< size_t >> distances;
          double dist_x, dist_y, dist;
          for (auto & point : points) {
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
          xi += dx;
        }
        yj += dy;
      }
      return nearest;
    }

    vector< vector< ssize_t >> & cached_nearest_for(const Transform & tf) const {
      static std::unordered_map< string, vector< vector< ssize_t >>> cache;
      string key = tf.cache_key(*this);
      if (!cache.contains(key)) cache[key] = nearest_for(tf);
      return cache[key];
    }
  };
}
