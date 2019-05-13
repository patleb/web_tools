require 'cod'

module Cod
  IOPair.class_eval do
    module WithBinMode
      def initialize(r=nil, w=nil)
        super
        self.r.binmode
        self.w.binmode
      end
    end
    prepend WithBinMode
  end
end
