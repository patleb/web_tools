module GDAL
  Raster.class_eval do
    module self::WithOverrides
      def initialize(narray, x0, x1, y0, y1, proj: nil, nodata: nil)
        x01_y01 = [x0, x1, y0, y1]
        if proj
          proj = proj.to_s
          nodata ? super(narray, narray.type, x01_y01, proj, [nodata]) : super(narray, narray.type, x01_y01, proj)
        else
          nodata ? super(narray, narray.type, x01_y01, '4326', [nodata]) : super(narray, narray.type, x01_y01)
        end
      end

      def transform(proj, nodata: nil, algo: nil)
        proj = proj.to_s
        if nodata
          algo ? super(proj, nodata, algo) : super(proj, nodata)
        else
          algo ? super(proj, nil, algo) : super(proj)
        end
      end
    end
    prepend self::WithOverrides
  end
end
