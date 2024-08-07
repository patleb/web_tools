module ActiveRecord
  module Type
    class Encrypted < ActiveRecord::Type::Text
      def serialize(value)
        if value&.start_with? Setting::SECRET
          Setting.decrypt(value)
        else
          value
        end
      end

      private

      def cast_value(value)
        if value&.start_with? Setting::SECRET
          value
        elsif value
          Setting.encrypt(value)
        end
      end
    end
  end
end

ActiveRecord::Type.register(:encrypted, ActiveRecord::Type::Encrypted)
