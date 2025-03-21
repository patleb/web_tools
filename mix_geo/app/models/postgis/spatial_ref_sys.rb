module Postgis
  class SpatialRefSys < ActiveRecord::Base
    self.primary_key = :srid
  end
end
