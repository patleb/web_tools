module NetCDF
  Att.class_eval do
    module self::WithOverrides
      def name=(new_name)
        super(new_name.to_s)
      end

      def read
        if type == Type::String
          super.first
        else
          super.to_a
        end
      end
    end
    prepend self::WithOverrides
  end
end
