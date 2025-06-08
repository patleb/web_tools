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

    auto _x_() const {
      return x;
    }

    auto _y_() const {
      return y;
    }

    auto points() const {
      vector< std::pair< double, double >> xy(size);
      for (size_t i = 0; i < size; ++i) xy[i] = std::make_pair(x[i], y[i]);
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
