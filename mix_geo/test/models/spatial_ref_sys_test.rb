require './test/test_helper'

CUSTOM_SRIDS = {
  '200_000': {
    grid_mapping_name: 'lambert_conformal_conic',
    standard_parallel: [50.0, 45.0],
    longitude_of_central_meridian: -59.9,
    latitude_of_projection_origin: 48.0,
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
  },
  '200_001': {
    grid_mapping_name: 'lambert_conformal_conic',
    standard_parallel: [50.0, 45.0],
    longitude_of_central_meridian: -81.75,
    latitude_of_projection_origin: 48.0,
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
  },
  '200_002': {
    grid_mapping_name: 'lambert_conformal_conic',
    standard_parallel: [50.0, 45.0],
    longitude_of_central_meridian: -130.0,
    latitude_of_projection_origin: 48.0,
    false_easting: 0.0,
    false_northing: 0.0,
    semi_major_axis: 6378.137,
    inverse_flattening: 298.2572235629991,
  },
}

class SpatialRefSysTest < ActiveSupport::TestCase
  before do
    CUSTOM_SRIDS.each do |srid, proj4|
      srid = srid.to_s.to_i
      if (sr = Postgis::SpatialRefSys.find_by(srid: srid))
        sr.update_proj4!(ocean_canada: true, **proj4)
      else
        Postgis::SpatialRefSys.create_proj4!(srid, ocean_canada: true, **proj4)
      end
    end
  end

  test '#proj4' do
    assert_equal({ init: 'epsg:3857' }, Postgis::SpatialRefSys.proj4(3857))
    assert_equal(
      { proj: 'llc', lat_1: 50.0, lat_2: 45.0, lon_0: -59.9, lat_0: 48.0, x_0: 0.0, y_0: 0.0, a: 6378.137,
        rf: 298.2572235629991, units: 'm', type: 'crs', no_defs: nil
      },
      Postgis::SpatialRefSys.proj4(200_000)
    )
  end
end
