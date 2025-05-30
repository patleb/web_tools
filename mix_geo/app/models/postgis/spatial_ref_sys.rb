# NOTE https://blog.cleverelephant.ca/2019/02/proj4-postgis.html
module Postgis
  class SpatialRefSys < ActiveRecord::Base
    self.primary_key = :srid

    def proj4
      proj4text.split('+')
        .reject(&:blank?).map(&:strip).map{ |kv| kv.include?('=') ? kv.split('=') : [kv, true] }.to_h
        .symbolize_keys!.transform_values!(&:cast_self)
    end
  end
end
