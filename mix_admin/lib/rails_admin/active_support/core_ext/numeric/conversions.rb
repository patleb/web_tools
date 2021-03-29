class Numeric
  module Conversions
    def pretty_int
      to_i.to_s.reverse.gsub(/...(?!-)(?=.)/, '\& ').reverse
    end

    def pretty_hours(**options)
      hh, mm, ss = to_hours
      if options[:ceil]
        hh += 1 if (mm != 0 || ss != 0)
        "#{hh}h"
      elsif options[:floor]
        "#{hh}h"
      else
        if hh == 0
          if mm == 0
            "#{ss}s"
          else
            "#{mm}m #{ss}s"
          end
        else
          "#{hh}h #{mm}m #{ss}s"
        end
      end
    end

    def pretty_days(**options)
      dd, hh, mm, ss = to_days
      if options[:ceil]
        dd += 1 if (hh != 0 || mm != 0 || ss != 0)
        "#{dd}d"
      elsif options[:floor]
        "#{dd}d"
      else
        if dd == 0
          if hh == 0
            if mm == 0
              "#{ss}s"
            else
              "#{mm}m #{ss}s"
            end
          else
            "#{hh}h #{mm}m #{ss}s"
          end
        else
          "#{dd}d #{hh}h #{mm}m #{ss}s"
        end
      end
    end
  end
  include Conversions
end
