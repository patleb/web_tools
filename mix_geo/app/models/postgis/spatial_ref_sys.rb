# NOTE https://blog.cleverelephant.ca/2019/02/proj4-postgis.html
module Postgis
  class SpatialRefSys < ActiveRecord::Base
    CF_ALIASES = {
      grid_mapping_name:                     :proj,
      false_easting:                         :x_0,
      false_northing:                        :y_0,
      scale_factor_at_projection_origin:     :k_0,
      scale_factor_at_central_meridian:      :k_0,
      standard_parallel:                     :lat,
      longitude_of_central_meridian:         :lon_0,
      longitude_of_projection_origin:        :lon_0,
      straight_vertical_longitude_from_pole: :lon_0,
      latitude_of_projection_origin:         :lat_0,
      semi_major_axis:                       :a,
      semi_minor_axis:                       :b,
      inverse_flattening:                    :rf,
      longitude_of_prime_meridian:           :pm,
    }
    CF_MAPPINGS = {
      'albers_conical_equal_area'      => 'aea',
      'azimuthal_equidistant'          => 'aeqd',
      'geostationary'                  => 'geos',
      'lambert_azimuthal_equal_area'   => 'laea',
      'lambert_conformal_conic'        => 'lcc',
      'lambert_cylindrical_equal_area' => 'cea',
      'latitude_longitude'             => 'longlat',
      'mercator'                       => 'merc',
      'oblique_mercator'               => 'omerc',
      'orthographic'                   => 'ortho',
      'polar_stereographic'            => 'stere',
      'rotated_latitude_longitude'     => 'ob_tran',
      'sinusoidal'                     => 'sinu',
      'stereographic'                  => 'stere',
      'transverse_mercator'            => 'tmerc',
      'vertical_perspective'           => 'nsper'
    }

    self.primary_key = :srid

    scope :from_proj, -> (proj) { where(crs_for(proj)) }

    def self.find_by_proj(proj)
      from_proj(proj).order(:srid).take
    end

    def self.proj_exists?(proj)
      from_proj(proj).exists?
    end

    def self.create_proj!(srid, proj)
      create! srid: srid, **crs_for(proj)
    end

    def self.crs_for(proj)
      case proj
      when Numeric then { srid: proj }
      when Hash    then { auth_name: nil, proj4text: proj4text(**proj) }
      else              { auth_name: nil, proj4text: proj }
      end
    end
    delegate :crs_for, to: :class

    def self.transform(x, y, srid: nil, proj: nil, **proj4)
      return [x, y] if srid == 4326
      geo = RGeo::CoordSys::Proj4.create(4326)
      if srid.nil?
        proj = proj4text(**proj4) unless proj4.empty?
        proj = RGeo::CoordSys::Proj4.create(proj)
      elsif proj == true || (200_000 <= srid && srid < 300_000)
        proj = RGeo::CoordSys::Proj4.create(find(srid).proj4text)
      else
        proj = RGeo::CoordSys::Proj4.create(srid)
      end
      RGeo::CoordSys::Proj4.transform_coords(geo, proj, x, y)
    end

    def self.proj4text(**proj4)
      proj4.transform_keys!{ |k| CF_ALIASES[k] || k }
      proj4[:proj] = CF_MAPPINGS[proj4[:proj]] || proj4[:proj]
      text = proj4.each_with_object([]) do |(key, value), memo|
        next memo << "+#{key}" if value.nil? || value == true
        next memo << "+#{key}=#{value.to_i? ? value.to_i : value}" unless value.is_a? Array
        value.each.with_index(1){ |v, i| memo << "+#{key}_#{i}=#{v.to_i? ? v.to_i : v}" }
      end
      text << '+type=crs'
      text << '+no_defs'
      text.join(' ')
    end

    def update_proj!(proj)
      update! crs_for(proj)
    end

    def proj4
      proj4text.split('+')
        .reject(&:blank?).map(&:strip).map{ |kv| kv.include?('=') ? kv.split('=') : [kv, true] }.to_h
        .symbolize_keys!.transform_values!(&:cast_self)
    end
  end
end
