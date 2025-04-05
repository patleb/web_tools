module Postgis
  OCEAN_CANADA_ALIASES = {
    grid_mapping_name: :proj,
    standard_parallel: :lat,
    longitude_of_central_meridian: :lon_0,
    latitude_of_projection_origin: :lat_0,
    false_easting: :x_0,
    false_northing: :y_0,
    semi_major_axis: :a,
    semi_minor_axis: :b,
    inverse_flattening: :rf,
  }
  OCEAN_CANADA_MAPPINGS = {
    'lambert_conformal_conic' => 'llc',
  }

  module OceanCanada
    extend ActiveSupport::Concern

    class_methods do
      def proj4text(crs: true, ocean_canada: false, **proj4)
        proj4 = ocean_canada_proj4(**proj4) if ocean_canada
        super(crs: crs, **proj4)
      end

      def ocean_canada_proj4(proj4)
        proj4.transform_keys!{ |k| OCEAN_CANADA_ALIASES[k] || k }
        proj4[:units] ||= 'm'
        proj4[:proj] = OCEAN_CANADA_MAPPINGS[proj4[:proj]] || proj4[:proj]
        proj4
      end
    end
  end
end
