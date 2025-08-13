namespace GDAL {
  using std::string;
  using std::vector;

  class Base {
    public:

    const OGRSpatialReference * srs = nullptr;

    Base() = default;

    explicit Base(const Ostring & proj):
      Base(srs_for(proj)) {
    }

    static auto _srid_(const string & proj)                  { return atoi(proj.c_str()); }
    static auto _wkt_(const string & proj)                   { return wkt_for(srs_for(proj)); }
    static auto _proj4_(const string & proj)                 { return proj4_for(srs_for(proj)); }
    static auto _axis_mapping_(const string & proj)          { return axis_mapping_for(srs_for(proj)); }
    static auto _orientation_(const string & proj)           { return orientation_for(srs_for(proj)); }
    static auto _orientation_names_(const string & proj)     { return orientation_names_for(srs_for(proj)); }
    static auto _mapping_strategy_(const string & proj)      { return mapping_strategy_for(srs_for(proj)); }
    static auto _mapping_strategy_name_(const string & proj) { return mapping_strategy_for(srs_for(proj)); }

    auto srid()                  const { return srid_for(srs); }
    auto wkt()                   const { return wkt_for(srs); }
    auto proj4()                 const { return proj4_for(srs); }
    auto axis_mapping()          const { return axis_mapping_for(srs); }
    auto orientation()           const { return orientation_for(srs); }
    auto orientation_names()     const { return orientation_names_for(srs); }
    auto mapping_strategy()      const { return mapping_strategy_for(srs); }
    auto mapping_strategy_name() const { return mapping_strategy_name_for(srs); }

    protected:

    explicit Base(const OGRSpatialReference * srs):
      srs(srs) {
    }

    static const OGRSpatialReference * srs_for(const Ostring & proj) {
      return srs_for(proj.value_or("4326"));
    }

    // NOTE gdal/port/cpl_mem_cache.h --> maxSize = 64
    static const OGRSpatialReference * srs_for(const string & proj) {
      static std::unordered_map< string, const OGRSpatialReference * > cache;
      if (cache.contains(proj)) return cache[proj];
      if (cache.size() >= 64) throw RuntimeError("too many SRS in use");
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
      cache[proj] = srs;
      return srs;
    }

    static int srid_for(const OGRSpatialReference * srs) {
      const char * auth = srs->GetAuthorityName(nullptr);
      const char * code = srs->GetAuthorityCode(nullptr);
      if (auth != nullptr && code != nullptr && string(auth) == "EPSG") {
        return atoi(code);
      }
      int number = srs->GetEPSGGeogCS();
      return number > 0 ? number : 0;
    }

    static string wkt_for(const OGRSpatialReference * srs) {
      char * c_str = nullptr;
      finally ensure([&]{
        CPLFree(c_str);
      });
      if (srs->exportToWkt(&c_str) != OGRERR_NONE) throw RuntimeError("export wkt error");
      string wkt(c_str);
      return wkt;
    }

    static string proj4_for(const OGRSpatialReference * srs) {
      char * c_str = nullptr;
      finally ensure([&]{
        CPLFree(c_str);
      });
      if (srs->exportToProj4(&c_str) != OGRERR_NONE) throw RuntimeError("export proj4 error");
      string proj4(c_str);
      return proj4;
    }

    static Vint axis_mapping_for(const OGRSpatialReference * srs) {
      return srs->GetDataAxisToSRSAxisMapping();
    }

    static Vdouble orientation_for(const OGRSpatialReference * srs) {
      OGRAxisOrientation orientation;
      auto mapping = axis_mapping_for(srs);
      if (mapping.size() != 2) throw RuntimeError("srs mapping.size() != 2");
      Vdouble xy(2);
      for (size_t i = 0; i < 2; ++i) {
        auto axis = mapping[i] - 1;
        srs->GetAxis(nullptr, axis, &orientation);
        switch (orientation) {
        case OAO_North: xy[i] = -1.0; break; // 1
        case OAO_South: xy[i] =  1.0; break; // 2
        case OAO_East:  xy[i] =  1.0; break; // 3
        case OAO_West:  xy[i] = -1.0; break; // 4
        default:
          // OAO_Other = 0
          // OAO_Up    = 5 --> Up (to space)
          // OAO_Down  = 6 --> Down (to Earth center)
          throw RuntimeError("unsupported axis");
        }
      }
      return xy;
    }

    static Vstring orientation_names_for(const OGRSpatialReference * srs) {
      OGRAxisOrientation orientation;
      auto mapping = axis_mapping_for(srs);
      Vstring xy(2);
      for (size_t i = 0; i < 2; ++i) {
        auto axis = mapping[i] - 1;
        srs->GetAxis(nullptr, axis, &orientation);
        switch (orientation) {
        case OAO_North: xy[i] = "North"; break;
        case OAO_South: xy[i] = "South"; break;
        case OAO_East:  xy[i] = "East";  break;
        case OAO_West:  xy[i] = "West";  break;
        }
      }
      return xy;
    }

    static int mapping_strategy_for(const OGRSpatialReference * srs) {
      return srs->GetAxisMappingStrategy();
    }

    static string mapping_strategy_name_for(const OGRSpatialReference * srs) {
      switch (mapping_strategy_for(srs)) {
      case OAMS_TRADITIONAL_GIS_ORDER: return "TRADITIONAL_GIS_ORDER";
      case OAMS_AUTHORITY_COMPLIANT:   return "AUTHORITY_COMPLIANT";
      case OAMS_CUSTOM:                return "CUSTOM";
      default:
        throw RuntimeError("unsupported mapping strategy");
      }
    }

    static void puts_mark() {
      static int marker_i = 0;
      CPLError(CE_Failure, CPLE_AppDefined, "%s", (string("mark ") + std::to_string(marker_i++)).c_str());
    }
  };
}
