require './test/test_helper'

PROJ4_200_000 = '+proj=lcc +lat_0=48 +lon_0=-59.9 +lat_1=50 +lat_2=45 +x_0=0 +y_0=0 +a=6378.137 +rf=298.2572235629991 +units=m +type=crs +no_defs'

class GDALTest < Rice::TestCase
  let(:data){ Numo::SFloat.new(2, 2).seq * 1.1 }
  let(:corner_4326){ [45, 51, -70, -68] }
  let(:corner_3857){ [5009377.085697311, 5705596.154676083, -11068715.659379493, -10372496.590400722] }

  test '#initialize' do
    nodata = Float::NAN
    data = Numo::SFloat[[nodata, 11], [22, nodata]]
    raster_3857 = GDAL::Raster.new(data, *corner_3857, proj: 3857, nodata: nodata)
    assert_equal GDAL::DataType::SFloat, raster_3857.type
    assert_equal data.shape, [raster_3857.width, raster_3857.height]
    assert_equal corner_3857, raster_3857.x01_y01.to_a
    assert_equal data.to_a.to_s, raster_3857.to_narray.to_a.to_s
    assert raster_3857.nodata.nan?

    nodata = -Float::INFINITY
    raster_4326 = raster_3857.transform(4326, nodata: nodata)
    assert_equal GDAL::DataType::SFloat, raster_4326.type
    assert_equal [3, 1], [raster_4326.width, raster_4326.height]
    assert_equal [45.0, 49.628696123011025, -70.0, -65.37130387698897], raster_4326.x01_y01.to_a
    assert_equal Numo::SFloat[[22], [nodata], [nodata]], raster_4326.to_narray
    assert_equal nodata, raster_4326.nodata
  end

  test '#transform' do
    raster_4326 = GDAL::Raster.new(data, *corner_4326)
    assert_equal GDAL::DataType::SFloat, raster_4326.type
    assert_equal data.shape, [raster_4326.width, raster_4326.height]
    assert_equal corner_4326, raster_4326.x01_y01.to_a
    assert_equal data, raster_4326.to_narray
    assert_nil raster_4326.nodata
    assert_equal corner_4326.first(2), raster_4326.x.to_a
    assert_equal corner_4326.last(2), raster_4326.y.to_a

    raster_same = raster_4326.transform(4326)
    assert_equal GDAL::DataType::SFloat, raster_same.type
    assert_equal data.shape, [raster_same.width, raster_same.height]
    assert_equal corner_4326, raster_same.x01_y01.to_a
    assert_equal data, raster_same.to_narray
    assert_nil raster_same.nodata

    assert_equal [corner_3857[0], corner_3857[2]], Postgis::SpatialRefSys.transform(45, -70, srid: 3857)
    assert_equal [5677294.030456952, -10446997.314774934], Postgis::SpatialRefSys.transform(51, -68, srid: 3857)

    raster_3857 = raster_4326.transform(3857)
    assert_equal GDAL::DataType::SFloat, raster_3857.type
    assert_equal data.shape, [raster_3857.width, raster_3857.height]
    assert_equal corner_3857, raster_3857.x01_y01.to_a
    assert_equal data, raster_3857.to_narray
    assert_nil raster_3857.nodata

    assert_equal [40841.9872702298, -3363.094394859862], Postgis::SpatialRefSys.transform(45, -70, proj: PROJ4_200_000)
    assert_equal [38555.37308123251, 229.63035717285263], Postgis::SpatialRefSys.transform(51, -68, proj: PROJ4_200_000)

    raster_200_000 = raster_4326.transform(PROJ4_200_000)
    assert_equal GDAL::DataType::SFloat, raster_200_000.type
    assert_equal data.shape, [raster_200_000.width, raster_200_000.height]
    assert_equal [40841.9872702298, 44504.720447929845, 3029.495102646343, 6692.228280346388], raster_200_000.x01_y01.to_a
    assert_equal data.transpose.flipud, raster_200_000.to_narray

    raster_back = raster_200_000.transform(4326)
    assert_equal GDAL::DataType::SFloat, raster_back.type
    assert_equal [3, 1], [raster_back.width, raster_back.height]
    assert_equal [43.31888536591117, 47.450983055140384, -69.40037544312334, -65.26827775389413], raster_back.x01_y01.to_a
    assert_equal Numo::SFloat[[0], [0], [1.1]], raster_back.to_narray
  end
end
