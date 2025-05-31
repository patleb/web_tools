module GDAL
  Base.class_eval do
    module self::WithNillableSRID
      def srid
        return if (srid = super) == 0
        srid
      end

      def orientation
        super.to_a
      end
    end
    prepend self::WithNillableSRID
  end
end
