module GDAL
  Vector.class_eval do
    module self::WithOverrides
      def initialize(x, y, proj: nil, **proj4)
        x = Array.wrap(x)
        y = Array.wrap(y)
        proj = proj.to_s if proj
        proj = GDAL.proj4text(**proj4) unless proj || proj4.empty?
        super(x, y, proj)
      end

      def x
        super.to_a
      end

      def y
        super.to_a
      end

      def first
        super.to_a
      end

      def last
        super.to_a
      end

      def minmax
        super.to_a
      end

      def points
        super.to_a
      end

      def reproject(proj = nil, **proj4)
        proj = proj ? proj.to_s : GDAL.proj4text(**proj4)
        super(proj)
      end
    end
    prepend self::WithOverrides

    def self.reproject(x, y, src_proj: nil, dst_proj:)
      array = x.is_a? Array
      src_proj = GDAL.proj4text(**src_proj) if src_proj.is_a? Hash
      dst_proj = GDAL.proj4text(**dst_proj) if dst_proj.is_a? Hash
      vector = new(x, y, proj: src_proj)
      vector = vector.reproject(dst_proj)
      vector = vector.x.zip(vector.y)
      array ? vector : vector.first
    end

    def to_a
      x.zip(y)
    end
  end
end
