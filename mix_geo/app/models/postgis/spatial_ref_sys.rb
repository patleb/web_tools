# NOTE https://blog.cleverelephant.ca/2019/02/proj4-postgis.html
module Postgis
  class SpatialRefSys < ActiveRecord::Base
    self.primary_key = :srid

    def self.reproject(x, y, src_proj:, dst_proj:)
      require 'rgeo/proj4'
      src = RGeo::CoordSys::Proj4.create(src_proj)
      dst = RGeo::CoordSys::Proj4.create(dst_proj)
      is_array = x.is_a? Array
      x, y = Array.wrap(x), Array.wrap(y)
      result = x.map.with_index do |xi, i|
        RGeo::CoordSys::Proj4.transform_coords(src, dst, xi, y[i])
      end
      is_array ? result : result.first
    end

    def proj4
      proj4text.split('+')
        .reject(&:blank?).map(&:strip).map{ |kv| kv.include?('=') ? kv.split('=') : [kv, true] }.to_h
        .symbolize_keys!.transform_values!(&:cast_self)
    end
  end
end
