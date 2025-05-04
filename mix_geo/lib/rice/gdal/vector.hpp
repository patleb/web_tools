namespace GDAL {
  class Vector : public Base {
    public:

    size_t size;

    Vector(vector< double > x, vector< double > y, string proj = "4326"):
      lon(x),
      lat(y),
      size(x.size()),
      srs(srs_for(proj)) {
      if (x.size() != y.size()) throw RuntimeError("size mismatch");
    }

    auto x() const {
      return lon;
    }

    auto y() const {
      return lat;
    }

    auto wkt() const {
      return wkt_for(srs);
    }

    auto transform(string dst_proj) const {
      auto dst_srs = srs_for(dst_proj);
      auto transform = OGRCreateCoordinateTransformation(&srs, &dst_srs);
      if (transform == nullptr) {
        throw RuntimeError("unable to create the transform");
      }
      finally ensure([&]{
        delete transform;
      });
      Vector dst(*this, dst_srs);
      if (!transform->Transform(size, dst.lon.data(), dst.lat.data())) {
        throw RuntimeError("unable to transform coordinates");
      }
      return dst;
    }

    private:

    Vector(const Vector & vector, const OGRSpatialReference & srs):
      lon(vector.lat), // OGRCoordinateTransformation#Transform uses (lat, lon)
      lat(vector.lon),
      size(vector.size),
      srs(srs) {
    }

    vector< double > lon;
    vector< double > lat;
    OGRSpatialReference srs;
  };
}
