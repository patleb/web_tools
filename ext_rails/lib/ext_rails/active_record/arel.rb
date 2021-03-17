require 'arel_extensions'
require_rel './arel'

module ArelExtensions
  module Attributes
    def ==(other)
      eql? other
    end

    def !=(other)
      !eql?(other)
    end
  end
end
