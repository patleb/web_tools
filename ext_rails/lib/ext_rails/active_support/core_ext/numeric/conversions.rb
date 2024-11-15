class Numeric
  module Conversions
    def pretty_int
      to_i.to_s.reverse.gsub(/...(?!-)(?=.)/, '\& ').reverse
    end
  end
  include Conversions
end
