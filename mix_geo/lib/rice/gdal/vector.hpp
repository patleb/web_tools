namespace GDAL {
  class Vector : public Base {
    public:

    Vdouble x;
    Vdouble y;
    size_t size;

    Vector() = default;

    Vector(const Vdouble & x, const Vdouble & y, const Ostring & proj = nil):
      Vector(x, y, srs_for(proj.value_or("4326"))) {
    }

    Vector(const Vdouble & x, const Vdouble & y, OGRSpatialReference * srs):
      Base::Base(srs),
      x(x),
      y(y),
      size(x.size()) {
      if (size != y.size()) throw RuntimeError("size mismatch");
    }

    auto _x_()   const { return x; }
    auto _y_()   const { return y; }
    auto first() const { return Vdouble{ x.front(), y.front() }; }
    auto last()  const { return Vdouble{ x.back(),  y.back() }; }

    Vdouble minmax() const {
      const auto [x_min, x_max] = std::minmax_element(x.begin(), x.end());
      const auto [y_min, y_max] = std::minmax_element(y.begin(), y.end());
      return Vdouble{ *x_min, *x_max, *y_min, *y_max };
    }

    vector< Point > points() const {
      vector< Point > xy; xy.reserve(size);
      for (size_t i = 0; i < size; ++i) xy.emplace_back(x[i], y[i], srs);
      return xy;
    }

    Vector reproject(const string & dst_proj) const {
      auto dst_srs = srs_for(dst_proj);
      if (dst_srs == srs) return Vector(*this);
      auto transform = OGRCreateCoordinateTransformation(srs, dst_srs);
      if (transform == nullptr) {
        throw RuntimeError("unable to create the transform");
      }
      finally ensure([&]{
        OGRCoordinateTransformation::DestroyCT(transform);
      });
      Vector dst(x, y, dst_srs);
      if (!transform->Transform(size, dst.x.data(), dst.y.data())) {
        throw RuntimeError("unable to transform coordinates");
      }
      return dst;
    }
  };
}
