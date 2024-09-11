module Admin
  module Fields
    class EnumArray < Enum
      prepend Field::AsArray

      register_option :multiple? do
        true
      end
    end
  end
end
