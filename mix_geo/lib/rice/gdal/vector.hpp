namespace GDAL {
  class Vector : public Base {
    public:

    Vdouble lon;
    Vdouble lat;
    size_t size;

    using Base::Base;

    Vector() = default;

    Vector(Vdouble x, Vdouble y, string proj = "4326"):
      Vector(x, y, srs_for(proj)) {
    }

    Vector(const Vdouble & x, const Vdouble & y, OGRSpatialReference * srs):
      Base(srs),
      lon(x),
      lat(y),
      size(x.size()) {
      if (size != y.size()) throw RuntimeError("size mismatch");
    }

    auto x() const {
      return lon;
    }

    auto y() const {
      return lat;
    }

    auto points() const {
      vector< std::pair< double, double >> xy(size);
      for (size_t i = 0; i < size; ++i) xy[i] = std::make_pair(lon[i], lat[i]);
      return xy;
    }

    Vector reproject(string dst_proj) const {
      auto dst_srs = srs_for(dst_proj);
      if (dst_srs == srs) return Vector(*this);
      auto transform = OGRCreateCoordinateTransformation(srs, dst_srs);
      if (transform == nullptr) {
        throw RuntimeError("unable to create the transform");
      }
      finally ensure([&]{
        OGRCoordinateTransformation::DestroyCT(transform);
      });
      Vector dst(this->lon, this->lat, dst_srs);
      if (!transform->Transform(size, dst.lon.data(), dst.lat.data())) {
        throw RuntimeError("unable to transform coordinates");
      }
      return dst;
    }
  };
}
