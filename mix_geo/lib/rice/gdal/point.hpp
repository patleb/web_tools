namespace GDAL {
  class Point : public Base {
    public:

    Point() = default;

    Point(double x, double y, const Ostring & proj = nil):
      Point(x, y, srs) {
    }

    Point(double x, double y, OGRSpatialReference * srs):
      Base::Base(srs),
      point(x, y) {
      point.assignSpatialReference(srs);
    }

    Point reproject(const string & dst_proj) const {
      auto dst_srs = srs_for(dst_proj);
      if (dst_srs == srs) return Point(*this);
      auto transform = OGRCreateCoordinateTransformation(srs, dst_srs);
      if (transform == nullptr) {
        throw RuntimeError("unable to create the transform");
      }
      finally ensure([&]{
        OGRCoordinateTransformation::DestroyCT(transform);
      });
      double x, y;
      if (!transform->Transform(1, &x, &y)) {
        throw RuntimeError("unable to transform coordinate");
      }
      return Point(x, y, dst_srs);
    }

    double x() const {
      return point.getX();
    }

    double y() const {
      return point.getY();
    }

    double distance(double x, double y) const {
      OGRPoint point(x, y);
      point.assignSpatialReference(srs);
      return this->point.Distance(&point);
    }

    private:

    OGRPoint point;
  };
}
