module ActiveRecord
  module Type
    class Encrypted < ActiveRecord::Type::Text
      def serialize(value)
        if value&.start_with? Setting::SECRET
          memoize(__method__, value) do
            Setting.decrypt(value)
          end
        else
          value
        end
      end

      private

      def cast_value(value)
        if value&.start_with? Setting::SECRET
          value
        elsif value
          memoize(__method__, value) do
            Setting.encrypt(value)
          end
        end
      end
    end
  end
end

ActiveRecord::Type.register(:encrypted, ActiveRecord::Type::Encrypted)
