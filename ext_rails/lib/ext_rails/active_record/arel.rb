require 'arel_extensions'
require_dir 'ext_rails/active_record/arel'

module ArelExtensions
  module Attributes
    ### NOTE ActiveRecord aliases == to eql?
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
