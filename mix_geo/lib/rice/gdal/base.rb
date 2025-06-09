module GDAL
  Base.class_eval do
    module self::WithOverrides
      extend ActiveSupport::Concern

      class_methods do
        def srid(proj)
          return if (srid = super(proj.to_s)) == 0
          srid
        end

        def wkt(proj)
          super(proj.to_s)
        end

        def proj4(proj)
          super(proj.to_s)
        end

        def orientation(proj)
          super(proj.to_s).to_a
        end
      end

      def srid
        return if (srid = super) == 0
        srid
      end

      def orientation
        super.to_a
      end
    end
    prepend self::WithOverrides
  end
end
