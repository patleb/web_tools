namespace GDAL {
  class Vector : public Base {
    public:

    using Base::Base;

    Vector(vector< double > x, vector< double > y, string proj = "4326"):
      Base(proj),
      lon(x),
      lat(y) {
      if (x.size() != y.size()) throw RuntimeError("size mismatch");
    }

    static auto transform_bounds(vector< double > x0n_y0n, string src_proj, string dst_proj, size_t density = 21) {
      if (x0n_y0n.size() != 4) throw RuntimeError("invalid x0n_y0n size");
      if (!density)            throw RuntimeError("density == 0");
      if (src_proj == dst_proj) return x0n_y0n;
      auto x0 = x0n_y0n[0], xn = x0n_y0n[1], y0 = x0n_y0n[2], yn = x0n_y0n[3];
      bool x_neg = (x0 > xn), y_neg = (y0 > yn);
      if (x_neg) { auto tmp = x0; x0 = xn; xn = tmp; }
      if (y_neg) { auto tmp = y0; y0 = yn; yn = tmp; }
      auto src_srs = srs_for(src_proj);
      auto dst_srs = srs_for(dst_proj);
      auto transform = create_transform(src_srs, dst_srs);
      finally ensure([&]{
        delete transform;
      });
      double x_min, x_max, y_min, y_max;
      transform->TransformBounds(x0, y0, xn, yn, &x_min, &y_min, &x_max, &y_max, density);
      if (x_neg) { auto tmp = x_min; x_min = x_max; x_max = tmp; }
      if (y_neg) { auto tmp = y_min; y_min = y_max; y_max = tmp; }
      return vector< double >{ x_min, x_max, y_min, y_max, };
    }

    auto size() const {
      return lon.size();
    }

    auto x() const {
      return lon;
    }

    auto y() const {
      return lat;
    }

    auto transform(string dst_proj) const {
      auto dst_srs = srs_for(dst_proj);
      auto transform = create_transform(srs, dst_srs);
      finally ensure([&]{
        delete transform;
      });
      Vector dst(*this, dst_srs);
      if (!transform->Transform(size(), dst.lon.data(), dst.lat.data())) {
        throw RuntimeError("unable to transform coordinates");
      }
      return dst;
    }

    private:

    static OGRCoordinateTransformation * create_transform(const OGRSpatialReference * src, const OGRSpatialReference * dst) {
      auto transform = OGRCreateCoordinateTransformation(src, dst);
      if (transform == nullptr) {
        throw RuntimeError("unable to create the transform");
      }
      return transform;
    }

    Vector(const Vector & vector, OGRSpatialReference * srs):
      Base(srs),
      lon(vector.lon),
      lat(vector.lat) {
    }

    vector< double > lon;
    vector< double > lat;
  };
}
