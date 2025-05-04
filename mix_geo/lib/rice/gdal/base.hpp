namespace GDAL {
  class Base {
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
      char * c_wkt = nullptr;
      srs.exportToWkt(&c_wkt);
      string wkt(c_wkt);
      CPLFree(c_wkt);
      return wkt;
    }

    auto wkt_for(const string & proj) const {
      return wkt_for(srs_for(proj));
    }
  };
}
