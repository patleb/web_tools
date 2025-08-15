require './test/test_helper'

CF_SRIDS = {
  200_000 => {
    grid_mapping_name: 'lambert_conformal_conic',
    latitude_of_projection_origin: 48.0,
    longitude_of_central_meridian: -59.9,
    standard_parallel: [50.0, 45.0],
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
    units: 'm',
  },
  200_001 => {
    grid_mapping_name: 'lambert_conformal_conic',
    latitude_of_projection_origin: 48.0,
    longitude_of_central_meridian: -81.75,
    standard_parallel: [50.0, 45.0],
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
    units: 'm',
  },
  200_002 => {
    grid_mapping_name: 'lambert_conformal_conic',
    latitude_of_projection_origin: 48.0,
    longitude_of_central_meridian: -130.0,
    standard_parallel: [50.0, 45.0],
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
    units: 'm',
  },
}
PROJ4_SRIDS = {
  200_000 => '+proj=lcc +lat_0=48 +lon_0=-59.9 +lat_1=50 +lat_2=45 +x_0=0 +y_0=0 +a=6378.137 +rf=298.2572235629991 +units=m +type=crs +no_defs',
  200_001 => '+proj=lcc +lat_0=48 +lon_0=-81.75 +lat_1=50 +lat_2=45 +x_0=0 +y_0=0 +a=6378.137 +rf=298.2572235629991 +units=m +type=crs +no_defs',
  200_002 => '+proj=lcc +lat_0=48 +lon_0=-130 +lat_1=50 +lat_2=45 +x_0=0 +y_0=0 +a=6378.137 +rf=298.2572235629991 +units=m +type=crs +no_defs',
}

class GDALTest < Rice::TestCase
  let(:corner_4326){ [-70, -68, 51, 45] }
  let(:corner_3857){ [-7792364.355529149, -7569725.373942603, 6621293.722740169, 5621521.486192066] }
  let(:x_4326) { corner_4326[0..1] }
  let(:y_4326) { corner_4326[2..3] }
  let(:x_3857) { corner_3857[0..1] }
  let(:y_3857) { corner_3857[2..3] }

  test '.proj4text' do
    CF_SRIDS.each do |srid, proj|
      assert_equal PROJ4_SRIDS[srid], GDAL.proj4text(**proj)
    end
  end

  context 'Vector' do
    test '.reproject' do
      geo_proj = [-62.5, 48.0]
      web_proj = [-6957468.174579599, 6106854.834885074]
      any_proj = [-193.81238399946488, 3.243495673962869]
      assert_equal web_proj, GDAL::Vector.reproject(*geo_proj, dst_proj: 3857)
      assert_equal any_proj, GDAL::Vector.reproject(*geo_proj, dst_proj: PROJ4_SRIDS[200_000])
      assert_equal any_proj, GDAL::Vector.reproject(*geo_proj, dst_proj: CF_SRIDS[200_000])
    end

    test '#reproject' do
      vector = GDAL::Vector.new(x_4326, y_4326)
      assert_equal 2, vector.size
      assert_equal x_4326, vector.x.to_a
      assert_equal y_4326, vector.y.to_a
      vector_3857 = vector.reproject(3857)
      assert_equal 2, vector_3857.size
      assert_equal x_3857, vector_3857.x.to_a
      assert_equal y_3857, vector_3857.y.to_a
      assert_equal x_3857.zip(y_3857), GDAL::Vector.reproject(x_4326, y_4326, dst_proj: 3857)
    end

    test '#srid,ans state-level AI laws for 10 yrs #proj4, #wkt' do
      vector = GDAL::Vector.new(x_3857, y_3857, proj: 3857)
      srid, proj4, wkt = vector.srid, vector.proj4, vector.wkt
      assert_equal 3857, srid
      vector = GDAL::Vector.new(x_3857, y_3857, proj: proj4)
      assert_equal proj4, vector.proj4
      vector = GDAL::Vector.new(x_3857, y_3857, proj: wkt)
      assert_equal wkt, vector.wkt
    end
  end

  context 'Raster' do
    test '#initialize' do
      fill_value = Float::NAN
      data = Tensor::SFloat[[fill_value, 11], [22, fill_value]]
      data.fill_value = fill_value
      raster_3857 = GDAL::Raster.new(data, *corner_3857, proj: 3857)
      assert_equal Tensor::Type::SFloat, raster_3857.type
      assert_equal data.shape, [raster_3857.width, raster_3857.height]
      assert_equal data.to_sql, raster_3857.z.to_sql
      assert raster_3857.fill_value.nan?

      raster_4326 = raster_3857.reproject(4326)
      assert_equal Tensor::Type::SFloat, raster_4326.type
      assert_equal raster_3857.shape, [raster_4326.width, raster_4326.height]
      assert_equal data.to_sql, raster_4326.z.to_sql
      assert_equal fill_value.to_s, raster_4326.fill_value.to_s
    end

    test '#reproject' do
      [:_reproject_, :reproject].each do |reproject|
        data = Tensor::SFloat.new(2, 2).seq
        raster_4326 = GDAL::Raster.new(data, *corner_4326)
        assert_equal Tensor::Type::SFloat, raster_4326.type
        assert_equal data.shape, [raster_4326.width, raster_4326.height]
        assert_equal corner_4326, raster_4326.x01_y01.to_a
        assert_equal data, raster_4326.z
        assert raster_4326.fill_value.nan?
        assert_equal corner_4326.first(2), raster_4326.x.to_a
        assert_equal corner_4326.last(2), raster_4326.y.to_a

        raster_same = raster_4326.send(reproject, 4326)
        assert_equal Tensor::Type::SFloat, raster_same.type
        assert_equal data.shape, [raster_same.width, raster_same.height]
        assert_equal corner_4326, raster_same.x01_y01.to_a
        assert_equal data, raster_same.z
        assert raster_same.fill_value.nan?

        assert_equal [corner_3857[0], corner_3857[3]], GDAL::Vector.reproject(-70, 45, dst_proj: 3857)
        assert_equal [corner_3857[1], corner_3857[2]], GDAL::Vector.reproject(-68, 51, dst_proj: 3857)

        raster_3857 = raster_4326.send(reproject, 3857)
        assert_equal Tensor::Type::SFloat, raster_3857.type
        assert_equal data.shape, [raster_3857.width, raster_3857.height]
        assert_equal corner_3857, raster_3857.x01_y01.to_a
        assert_equal data, raster_3857.z
        assert raster_3857.fill_value.nan?

        assert_equal [-794.1116006197351, -281.5630954213741], GDAL::Vector.reproject(-70, 45, dst_proj: PROJ4_SRIDS[200_000])
        assert_equal [-568.1017458002922, 363.2252599054433], GDAL::Vector.reproject(-68, 51, dst_proj: PROJ4_SRIDS[200_000])

        raster_200_000 = raster_4326.send(reproject, PROJ4_SRIDS[200_000])
        assert_equal Tensor::Type::SFloat, raster_200_000.type
        assert_equal data.shape, [raster_200_000.width, raster_200_000.height]
        assert_equal [-794.1116006197351, -568.1017458002922, 379.6478615484937, -299.9919342125634], raster_200_000.x01_y01.to_a
        assert_equal data, raster_200_000.z

        raster_back = raster_200_000.send(reproject, 4326)
        assert_equal Tensor::Type::SFloat, raster_back.type
        assert_equal [2, 2], [raster_back.width, raster_back.height]
        assert_equal [-71.21739255950133, -67.12358202854078, 51.14666626779211, 44.83557451139183], raster_back.x01_y01.to_a
        assert_equal data, raster_back.z
      end
    end
  end
end
