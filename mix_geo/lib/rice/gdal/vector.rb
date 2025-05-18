module GDAL
  Vector.class_eval do
    module self::WithOverrides
      extend ActiveSupport::Concern

      class_methods do
        def transform_bounds(x0n_y0n, src_proj, dst_proj, density: nil)
          super(x0n_y0n, src_proj.to_s, dst_proj.to_s, density).to_a
        end
      end

      def initialize(x, y, proj: nil, **proj4)
        x = Array.wrap(x)
        y = Array.wrap(y)
        return super(x, y, proj.to_s) if proj
        return super(x, y, GDAL.proj4text(**proj4)) unless proj4.empty?
        super(x, y)
      end

      def transform(proj = nil, **proj4)
        proj ? super(proj.to_s) : super(GDAL.proj4text(**proj4))
      end
    end
    prepend self::WithOverrides

    def self.transform(x, y, src_proj: nil, dst_proj:)
      array = x.is_a? Array
      src_proj = GDAL.proj4text(**src_proj) if src_proj.is_a? Hash
      dst_proj = GDAL.proj4text(**dst_proj) if dst_proj.is_a? Hash
      vector = new(x, y, proj: src_proj)
      vector = vector.transform(dst_proj)
      vector = vector.x.zip(vector.y)
      array ? vector : vector.first
    end
  end
end
