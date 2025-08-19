namespace GDAL {
  class Point : public Base {
    public:

    Point() = default;

    Point(double x, double y, const Ostring & proj = nil):
      Point(x, y, srs_for(proj)) {
    }

    Point(double x, double y, const OGRSpatialReference * srs):
      Base::Base(srs),
      point(x, y) {
      point.assignSpatialReference(srs);
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
