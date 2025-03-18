module NetCDF
  Dim.class_eval do
    module self::WithOverrides
      def name=(new_name)
        super(new_name.to_s)
      end
    end
    prepend self::WithOverrides
  end
end
