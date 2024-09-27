module Admin
  module Fields
    class Hidden < Admin::Field
      def self.has?(section, property)
        MixAdmin.config.hidden_fields.include? property.name
      end

      register_option :input_type do
        :hidden
      end

      register_option :label do
        false
      end

      register_option :help do
        false
      end

      def allowed_field?
        super && section.is_a?(Admin::Sections::New)
      end
    end
  end
end
