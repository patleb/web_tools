# frozen_string_literal: false

# NOTE https://blog.cleverelephant.ca/2019/02/proj4-postgis.html
module Postgis
  class SpatialRefSys < ActiveRecord::Base
    prepend OceanCanada

    self.primary_key = :srid

    scope :from_proj4, -> (proj4) { where(crs_for(proj4)) }

    def self.find_by_proj4(proj4)
      from_proj4(proj4).order(:srid).take
    end

    def self.proj4_exists?(proj4)
      from_proj4(proj4).exists?
    end

    def self.create_proj4!(srid, proj4)
      create! srid: srid, **crs_for(proj4)
    end

    def self.crs_for(proj4)
      { proj4text: proj4text(**proj4), }
    end
    delegate :crs_for, to: :class

    def self.proj4text(crs: true, **proj4)
      text = proj4.reduce('') do |string, (key, value)|
        next string << " +#{key}" if value.nil?
        next string << " +#{key}=#{value}" unless value.is_a? Array
        value.each.with_index(1){ |v, i| string << " +#{key}_#{i}=#{v}" }
        string
      end
      text << ' +type=crs' if crs
      text << ' +no_defs'
      text
    end

    def self.proj4(srid)
      find(srid).proj4
    end

    def update_proj4!(proj4)
      update! crs_for(proj4)
    end

    def proj4
      if auth_name.nil?
        proj4text.split('+').reject(&:blank?).map(&:strip).map{ |kv| kv.include?('=') ? kv.split('=') : [kv, nil] }
          .to_h.symbolize_keys!.transform_values!(&:cast_self)
      else
        { init: "epsg:#{srid}" }
      end
    end
  end
end
