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

class SpatialRefSysTest < ActiveSupport::TestCase
  before do
    PROJ4_SRIDS.each do |srid, proj|
      Postgis::SpatialRefSys.create_proj! srid, proj
    end
  end

  test '.proj4text' do
    CF_SRIDS.each do |srid, proj|
      assert_equal PROJ4_SRIDS[srid], Postgis::SpatialRefSys.proj4text(**proj)
    end
  end

  test '.transform' do
    geo_proj = [-62.5, 48.0]
    web_proj = [-6957468.174579599, 6106854.834885074]
    any_proj = [-193.81238399946488, 3.243495673962869]
    assert_equal web_proj, Postgis::SpatialRefSys.transform(*geo_proj, srid: 3857)
    assert_equal any_proj, Postgis::SpatialRefSys.transform(*geo_proj, srid: 200_000)
    assert_equal any_proj, Postgis::SpatialRefSys.transform(*geo_proj, srid: 200_000, proj: true)
    assert_equal any_proj, Postgis::SpatialRefSys.transform(*geo_proj, proj: PROJ4_SRIDS[200_000])
    assert_equal any_proj, Postgis::SpatialRefSys.transform(*geo_proj, **CF_SRIDS[200_000])
  end
end
