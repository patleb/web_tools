module Postgis
  class SpatialRefSys < ActiveRecord::Base
    pyimport :pyproj
    delegate :pyproj, to: :class

    CF_KEYS_ALIASES = { # pyproj typo errors
      false_easting: :fase_easting,
      false_northing: :fase_northing,
    }
    CF_KEYS_EXCLUDED = %i(
      _FillValue
      epsg_code
    )

    self.primary_key = :srid

    scope :from_projection, -> (projection) { where(crs_for(projection)) }

    def self.find_by_projection(projection)
      from_projection(projection).order(:srid).take
    end

    def self.projection_exists?(projection)
      from_projection(projection).exists?
    end

    def self.create_projection!(srid, projection)
      create! srid: srid, auth_name: 'unknown', auth_srid: srid, **crs_for(projection)
    end

    def self.crs_for(projection)
      cf = projection.symbolize_keys.transform_keys{ |k| CF_KEYS_ALIASES[k] || k }.except(*CF_KEYS_EXCLUDED)
      crs = pyproj.crs.CRS.from_cf(cf, true)
      { srtext: crs.to_wkt, proj4text: crs.to_proj4 }
    end
    delegate :crs_for, to: :class

    def update_projection!(projection)
      update! crs_for(projection)
    end
  end
end
