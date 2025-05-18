namespace GDAL {
  class Base {
    public:

    explicit Base(const string & proj):
      Base(srs_for(proj)) {
    }

    auto srid() const {
      return srid_for(srs);
    }

    auto wkt() const {
      return wkt_for(srs);
    }

    auto proj4() const {
      return proj4_for(srs);
    }

    protected:

    OGRSpatialReference * srs = nullptr;

    explicit Base(OGRSpatialReference * srs):
      srs(srs) {
    }

    auto orientation() const {
      return orientation_for(srs);
    }

    static vector< double > orientation_for(OGRSpatialReference * srs) {
      OGRAxisOrientation orientation;
      vector< double > x_y(2);
      for (size_t i = 0; i < 2; ++i) {
        srs->GetAxis(nullptr, i, &orientation);
        switch (orientation) {
        case OAO_North: x_y[i] = -1.0; break; // 1
        case OAO_South: x_y[i] =  1.0; break; // 2
        case OAO_East:  x_y[i] =  1.0; break; // 3
        case OAO_West:  x_y[i] = -1.0; break; // 4
        default:
          // OAO_Other = 0
          // OAO_Up    = 5 --> Up (to space)
          // OAO_Down  = 6 --> Down (to Earth center)
          throw RuntimeError("unsupported axis");
        }
      }
      return x_y;
    }

    static OGRSpatialReference * srs_for(string proj) {
      static std::unordered_map< string, OGRSpatialReference * > srs_cache;
      if (srs_cache.contains(proj)) return srs_cache[proj];
      OGRErr e;
      const char * c_str = proj.c_str();
      auto srs = new OGRSpatialReference;
      int srid = atoi(c_str);
      if (srid) {
        e = srs->importFromEPSG(srid);
      } else if (proj[0] == '+') {
        e = srs->importFromProj4(c_str);
      } else {
        e = srs->importFromWkt(c_str);
      }
      if (e != OGRERR_NONE) {
        delete srs;
        throw RuntimeError("invalid proj");
      }
      srs->SetAxisMappingStrategy(OAMS_TRADITIONAL_GIS_ORDER);
      srs_cache[proj] = srs;
      return srs;
    }

    static int srid_for(OGRSpatialReference * srs) {
      const char * auth = srs->GetAuthorityName(nullptr);
      const char * code = srs->GetAuthorityCode(nullptr);
      if (auth != nullptr && code != nullptr && string(auth) == "EPSG") {
        return atoi(code);
      }
      int number = srs->GetEPSGGeogCS();
      return number > 0 ? number : 0;
    }

    static auto srid_for(const string & proj) {
      return atoi(proj.c_str());
    }

    static string wkt_for(OGRSpatialReference * srs) {
      char * c_str = nullptr;
      finally ensure([&]{
        CPLFree(c_str);
      });
      if (srs->exportToWkt(&c_str) != OGRERR_NONE) throw RuntimeError("export wkt error");
      string wkt(c_str);
      return wkt;
    }

    static auto wkt_for(const string & proj) {
      return wkt_for(srs_for(proj));
    }

    static string proj4_for(OGRSpatialReference * srs) {
      char * c_str = nullptr;
      finally ensure([&]{
        CPLFree(c_str);
      });
      if (srs->exportToProj4(&c_str) != OGRERR_NONE) throw RuntimeError("export proj4 error");
      string proj4(c_str);
      return proj4;
    }

    static auto proj4_for(const string & proj) {
      return proj4_for(srs_for(proj));
    }

    static void puts_mark() {
      static int marker_i = 0;
      CPLError(CE_Failure, CPLE_AppDefined, "%s", (string("mark ") + std::to_string(marker_i++)).c_str());
    }
  };
}
