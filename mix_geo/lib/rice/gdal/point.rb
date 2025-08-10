module GDAL
  Point.class_eval do
    module self::WithOverrides
      def initialize(x, y, proj: nil, **proj4)
        proj = proj.to_s if proj
        proj = GDAL.proj4text(**proj4) unless proj || proj4.empty?
        super(x, y, proj)
      end

      def reproject(proj = nil, **proj4)
        proj = proj ? proj.to_s : GDAL.proj4text(**proj4)
        super(proj)
      end
    end
    prepend self::WithOverrides

    def to_a
      [x, y]
    end
  end
end
