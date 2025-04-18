#undef STRCASECMP
#undef STRNCASECMP
#include <gdal_priv.h>
#include <gdalwarper.h>

namespace GDAL {
  using std::string;
  using std::vector;
  // using NaN  =  std::numeric_limits<double>::quiet_NaN(); // std::isnan(double)
  // using Inf  =  std::numeric_limits<double>::infinity();  // std::isinf(double) --> true also for NInf
  // using NInf = -std::numeric_limits<double>::infinity();  // double == NInf

  enum class AlgoType {
    Nearest     = GRA_NearestNeighbour, // 0
    Bilinear    = GRA_Bilinear,         // 1
    Cubic       = GRA_Cubic,            // 2
    CubicSpline = GRA_CubicSpline,      // 3
    Lanczos     = GRA_Lanczos,          // 4
    Average     = GRA_Average,          // 5
    Mode        = GRA_Mode,             // 6
    Max         = GRA_Max,              // 8
    Min         = GRA_Min,              // 9
    Median      = GRA_Med,              // 10
    Q1          = GRA_Q1,               // 11
    Q3          = GRA_Q3,               // 12
    Sum         = GRA_Sum,              // 13
    RMS         = GRA_RMS,              // 14
  };

  enum class DataType {
    Unknown = GDT_Unknown, // 0
    Int8    = GDT_Int8,    // 14
    Int16   = GDT_Int16,   // 3
    Int32   = GDT_Int32,   // 5
    Int64   = GDT_Int64,   // 13
    SFloat  = GDT_Float32, // 6
    DFloat  = GDT_Float64, // 7
    UInt8   = GDT_Byte,    // 1
    UInt16  = GDT_UInt16,  // 2
    UInt32  = GDT_UInt32,  // 4
    UInt64  = GDT_UInt64,  // 12
  };

  auto gdal_type(Numo::Type type_id) {
    switch (type_id) {
    case Numo::Type::Int8:   return GDT_Int8;
    case Numo::Type::Int16:  return GDT_Int16;
    case Numo::Type::Int32:  return GDT_Int32;
    case Numo::Type::Int64:  return GDT_Int64;
    case Numo::Type::SFloat: return GDT_Float32;
    case Numo::Type::DFloat: return GDT_Float64;
    case Numo::Type::UInt8:  return GDT_Byte;
    case Numo::Type::UInt16: return GDT_UInt16;
    case Numo::Type::UInt32: return GDT_UInt32;
    case Numo::Type::UInt64: return GDT_UInt64;
    default:                 return GDT_Unknown;
    }
  }

  class Raster {
    public:

    Raster(Numo::NArray grid, Numo::Type type_id, double x01_y01[4], string proj = "4326", double * nodata = nullptr) {
      auto shape = grid.shape();
      if (shape.size() != 2) {
        throw RuntimeError("invalid raster dimensions");
      }
      int width = shape[0];
      if (width < 2) {
        throw RuntimeError("invalid x axis size");
      }
      int height = shape[1];
      if (height < 2) {
        throw RuntimeError("invalid y axis size");
      }
      auto x0 = x01_y01[0], x1 = x01_y01[1], y0 = x01_y01[2], y1 = x01_y01[3];
      double geo[6] = { x0, (x1 - x0), 0, y0, 0, -(y1 - y0) };
      string wkt = wkt_for(proj);
      dataset = create_dataset(width, height, gdal_type(type_id));
      dataset->SetGeoTransform(geo);
      dataset->SetProjection(wkt.c_str());
      write_dataset(dataset, const_cast< void * >(grid.read_ptr()));
      if (nodata != nullptr) {
        dataset->GetRasterBand(1)->SetNoDataValue(*nodata);
      }
    }

    Raster(const Raster & raster):
      dataset(copy_dataset(raster.dataset)) {
    }

    ~Raster() {
      GDALClose(dataset);
    }

    auto wkt() const {
      return string(dataset->GetProjectionRef());
    }

    auto type() const {
      return static_cast< DataType >(dataset->GetRasterBand(1)->GetRasterDataType());
    }

    auto width() const {
      return static_cast< size_t >(dataset->GetRasterXSize());
    }

    auto height() const {
      return static_cast< size_t >(dataset->GetRasterYSize());
    }

    auto shape() const {
      return vector< size_t >{ width(), height() };
    }

    auto x01_y01() const {
      auto geo = geo_transform(dataset);
      return vector< double >{ geo[0], geo[0] + geo[1], geo[3], geo[3] - geo[5] };
    }

    auto x() const {
      auto width = this->width();
      auto x01_y01 = this->x01_y01();
      auto x0 = x01_y01[0], x1 = x01_y01[1];
      vector< double > x(width);
      auto step = x1 - x0;
      for (size_t i = 0; i < width; ++i, x0 += step) {
        x[i] = x0;
      }
      return x;
    }

    auto y() const {
      auto height = this->height();
      auto x01_y01 = this->x01_y01();
      auto y0 = x01_y01[2], y1 = x01_y01[3];
      vector<double> y(height);
      auto step = y1 - y0;
      for (size_t j = 0; j < height; ++j, y0 += step) {
        y[j] = y0;
      }
      return y;
    }

    auto nodata() const {
      int has_nodata;
      std::optional< double > nodata = dataset->GetRasterBand(1)->GetNoDataValue(&has_nodata);
      return has_nodata ? nodata : std::nullopt;
    }

    auto to_narray() const {
      switch (type()) {
      <%- %i(Int8 Int16 Int32 Int64 SFloat DFloat UInt8 UInt16 UInt32 UInt64).each do |type| -%>
      case DataType::<%= type %>: {
        auto grid = Numo::<%= type %>({ width(), height() });
        read_dataset(dataset, grid.write_ptr());
        return Numo::NType(grid);
      }
      <%- end -%>
      default:
        throw RuntimeError("unknown type");
      }
    }

    auto transform(string proj, double * nodata = nullptr, AlgoType algo = AlgoType::Nearest) const {
      void * transformer;
      CPLErr e;
      GDALRasterBand * band = dataset->GetRasterBand(1);
      GDALDataType type = band->GetRasterDataType();
      string wkt = wkt_for(proj);
      string src_wkt = dataset->GetProjectionRef();
      if (src_wkt == wkt) {
        return Raster(*this);
      }
      transformer = GDALCreateGenImgProjTransformer(dataset, src_wkt.c_str(), NULL, wkt.c_str(), FALSE, 0, 1);
      double geo[6];
      int width = 0;
      int height = 0;
      e = GDALSuggestedWarpOutput(dataset, GDALGenImgProjTransform, transformer, geo, &width, &height);
      GDALDestroyGenImgProjTransformer(transformer);
      if (e != CE_None) {
        throw RuntimeError("Failed to get suggested warp output.");
      }
      int has_nodata;
      auto src_nodata = band->GetNoDataValue(&has_nodata);
      GDALDataset * dst_dataset = create_dataset(width, height, type);
      dst_dataset->SetGeoTransform(geo);
      dst_dataset->SetProjection(wkt.c_str());
      if (has_nodata) {
        dst_dataset->GetRasterBand(1)->SetNoDataValue(nodata != nullptr ? *nodata : src_nodata);
      }
      transformer = GDALCreateGenImgProjTransformer(dataset, src_wkt.c_str(), dst_dataset, wkt.c_str(), FALSE, 0, 1);
      GDALWarpOptions * warp_options = GDALCreateWarpOptions();
      warp_options->hSrcDS = dataset;
      warp_options->hDstDS = dst_dataset;
      warp_options->nBandCount = 1;
      warp_options->panSrcBands = (int *)CPLMalloc(sizeof(int));
      warp_options->panDstBands = (int *)CPLMalloc(sizeof(int));
      warp_options->panSrcBands[0] = 1;
      warp_options->panDstBands[0] = 1;
      warp_options->eResampleAlg = static_cast< GDALResampleAlg >(algo);
      warp_options->pfnTransformer = GDALGenImgProjTransform;
      warp_options->pTransformerArg = transformer;
      if (has_nodata) {
        warp_options->padfSrcNoDataReal = (double *)CPLMalloc(sizeof(double));
        warp_options->padfDstNoDataReal = (double *)CPLMalloc(sizeof(double));
        warp_options->padfSrcNoDataReal[0] = src_nodata;
        warp_options->padfDstNoDataReal[0] = nodata != nullptr ? *nodata : src_nodata;
        warp_options->papszWarpOptions = CSLSetNameValue(warp_options->papszWarpOptions, "INIT_DEST", "NO_DATA");
      }
      GDALWarpOperation warp;
      warp.Initialize(warp_options);
      warp.ChunkAndWarpImage(0, 0, width, height);
      GDALDestroyGenImgProjTransformer(transformer);
      GDALDestroyWarpOptions(warp_options);
      return Raster(dst_dataset);
    }

    protected:

    GDALDataset * create_dataset(int width, int height, GDALDataType type) const {
      GDALDriver * driver = GetGDALDriverManager()->GetDriverByName("MEM");
      if (!driver) {
        throw RuntimeError("MEM driver not available.");
      }
      GDALDataset * dataset = driver->Create("", width, height, 1, type, nullptr);
      if (!dataset) {
        throw RuntimeError("Failed to create memory dataset.");
      }
      return dataset;
    }

    void read_dataset(GDALDataset * dataset, void * data, bool free_dataset = false, bool free_data = false) const {
      GDALRasterBand * band = dataset->GetRasterBand(1);
      int width = dataset->GetRasterXSize();
      int height = dataset->GetRasterYSize();
      CPLErr e = band->RasterIO(GF_Read, 0, 0, width, height, data, width, height, band->GetRasterDataType(), 0, 0);
      if (e != CE_None) {
        if (free_dataset) GDALClose(dataset);
        if (free_data) CPLFree(data);
        throw RuntimeError("Failed to read data.");
      }
    }

    void write_dataset(GDALDataset * dataset, void * data, bool free_dataset = false, bool free_data = false) const {
      GDALRasterBand * band = dataset->GetRasterBand(1);
      int width = dataset->GetRasterXSize();
      int height = dataset->GetRasterYSize();
      CPLErr e = band->RasterIO(GF_Write, 0, 0, width, height, data, width, height, band->GetRasterDataType(), 0, 0);
      if (e != CE_None) {
        if (free_dataset) GDALClose(dataset);
        if (free_data) CPLFree(data);
        throw RuntimeError("Failed to write data.");
      }
    }

    GDALDataset * copy_dataset(GDALDataset * dataset) const {
      CPLErr e;
      GDALRasterBand * band = dataset->GetRasterBand(1);
      GDALDataType type = band->GetRasterDataType();
      int width = dataset->GetRasterXSize();
      int height = dataset->GetRasterYSize();
      auto geo = geo_transform(dataset);
      void * buffer = CPLMalloc(GDALGetDataTypeSizeBytes(type) * width * height);
      GDALDataset * dst_dataset = create_dataset(width, height, type);
      dst_dataset->SetGeoTransform(geo.data());
      dst_dataset->SetProjection(dataset->GetProjectionRef());
      int has_nodata;
      auto nodata = band->GetNoDataValue(&has_nodata);
      if (has_nodata) {
        dst_dataset->GetRasterBand(1)->SetNoDataValue(nodata);
      }
      read_dataset(dataset, buffer, false, true);
      write_dataset(dst_dataset, buffer, true, true);
      CPLFree(buffer);
      return dst_dataset;
    }

    vector< double > geo_transform(GDALDataset * dataset) const {
      double geo[6];
      if (dataset->GetGeoTransform(geo) != CE_None) {
        throw RuntimeError("Failed to get geo transform.");
      }
      return vector< double >(geo, geo + 6);
    }

    string wkt_for(const string & proj) const {
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
      char * c_wkt = nullptr;
      srs.exportToWkt(&c_wkt);
      string wkt(c_wkt);
      CPLFree(c_wkt);
      return wkt;
    }

    private:

    explicit Raster(GDALDataset * dataset):
      dataset(dataset) {
    }

    GDALDataset * dataset = nullptr;
  };
}
