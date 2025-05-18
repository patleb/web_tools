# TODO redirect stderr to string and catch PROJ errors
module GDAL
  Raster.class_eval do
    module self::WithOverrides
      def initialize(narray, x0, x1, y0, y1, proj: nil, nodata: nil)
        super(narray, narray.type, [x0, x1, y0, y1], proj&.to_s, nodata)
      end

      def shape
        super.to_a
      end

      def x01_y01
        super.to_a
      end

      def bounds
        super.to_a
      end

      def reproject(proj, nodata: nil, fill_ratio: nil, algo: nil)
        super(proj.to_s, nodata, fill_ratio, algo)
      end
    end
    prepend self::WithOverrides
  end
end
