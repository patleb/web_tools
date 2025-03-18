module NetCDF
  Var.class_eval do
    module self::WithOverrides
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
