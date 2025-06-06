module NetCDF
  Att.class_eval do
    module self::WithOverrides
      def name=(new_name)
        super(new_name.to_s)
      end

      def read
        numeric? ? super.to_a : super.first
      end
    end
    prepend self::WithOverrides

    def dig(*indexes)
      return if indexes.size != 1
      read[indexes.first] rescue nil
    end

    def numeric?
      type != Type::String
    end
  end
end
