module GDAL
  Base.class_eval do
    module self::WithOverrides
      extend ActiveSupport::Concern

      class_methods do
        def directions(proj = nil)
          super(proj&.to_s).to_a
        end
      end

      def srid
        return if (srid = super) == 0
        srid
      end

      def directions
        super.to_a
      end
    end
    prepend self::WithOverrides
  end
end
