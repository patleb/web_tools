### NOTE
# (x, y) --> (lon, lat)
# East or South: x0, x1, ..., xn --> x{i} > x{i-1}
# West or North: x0, x1, ..., xn --> x{i} < x{i-1}
module GDAL
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
  }.to_hwka
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
end
