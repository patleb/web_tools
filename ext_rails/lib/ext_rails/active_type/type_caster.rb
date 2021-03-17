require 'active_type/type_caster'

module ActiveType
  class TypeCaster
    module NativeCasters
      class DelegateToRails5Type
        private

        def lookup(type)
          if !type.is_a?(Symbol) && type.respond_to?(:cast)
            type
          else
            ActiveRecord::Type.lookup(type, adapter: nil)
          end
        rescue ::ArgumentError
          ActiveRecord::Type::Value.new
        end
      end
    end
  end
end
