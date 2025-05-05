namespace GDAL {
  class Base {
    public:

    int srid = 0;

    explicit Base(int srid):
      srid(srid) {
    }

    explicit Base(const string & proj):
      srid(atoi(proj.c_str())) {
    }

    protected:

    auto srs_for(const string & proj) const {
      OGRErr e;
      const char * proj4 = proj.c_str();
      OGRSpatialReference srs;
      int srid = atoi(proj4);
      if (srid) {
        e = srs.importFromEPSG(srid);
      } else {
        e = srs.importFromProj4(proj4);
      }
      if (e != OGRERR_NONE) {
        throw RuntimeError("invalid proj");
      }
      return srs;
    }

    auto wkt_for(const OGRSpatialReference & srs) const {
      char * c_str = nullptr;
      srs.exportToWkt(&c_str);
      string wkt(c_str);
      CPLFree(c_str);
      return wkt;
    }

    auto wkt_for(const string & proj) const {
      return wkt_for(srs_for(proj));
    }

    auto proj4_for(const OGRSpatialReference & srs) const {
      char * c_str = nullptr;
      srs.exportToProj4(&c_str);
      string proj4(c_str);
      CPLFree(c_str);
      return proj4;
    }

    auto proj4_for(const string & proj) const {
      return proj4_for(srs_for(proj));
    }
  };
}
