module ActiveRecord
  module Type
    class Encrypted < ActiveRecord::Type::Text
      def serialize(value)
        if value.to_s.start_with? Setting::SECRET
          Setting.decrypt(value)
        else
          value
        end
      end

      private

      def cast_value(value)
        if value.to_s.start_with? Setting::SECRET
          value
        else
          Setting.encrypt(value.to_s) if value.present?
        end
      end
    end
  end
end

ActiveRecord::Type.register(:encrypted, ActiveRecord::Type::Encrypted)
