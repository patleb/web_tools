module GDAL
  Base.class_eval do
    module self::WithNillableSRID
      def srid
        return if (srid = super) == 0
        srid
      end
    end
    prepend self::WithNillableSRID
  end
end
