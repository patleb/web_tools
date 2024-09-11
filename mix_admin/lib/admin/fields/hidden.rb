module Admin
  module Fields
    class Hidden < Admin::Field
      def self.has?(section, property)
        MixAdmin.config.hidden_fields.include? property.name
      end

      register_option :view_helper do
        :hidden_field
      end

      register_option :label do
        false
      end

      register_option :help do
        false
      end

      def allowed_field?
        super && section.is_a?(Admin::Sections::Edit)
      end

      def generic_help
        false
      end
    end
  end
end
