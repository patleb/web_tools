require 'arel_extensions'
require_rel './arel'

module ArelExtensions
  module Attributes
    # use :eq instead
    def ==(other)
      eql? other
    end

    # use :not_eq insead
    def !=(other)
      !eql?(other)
    end
  end
end
