module Admin
  module Fields
    class ForeignKey < Admin::Field
      def self.has?(section, property)
        section.model.associations.find do |association|
          association.type == :belongs_to && association.foreign_key == property.name
        end
      end
      class << self
        alias_method :association_for, :has?
      end

      register_option :array_separator do
        '<br>'.html_safe
      end

      register_option :array_bullet do
        '- '.html_safe
      end

      def format_value(value)
        "#{property_model.label.upcase_first} ##{value}"
      end

      def format_index(value)
        foreign_key_link(value)
      end

      def input_type
        :number
      end

      def search_type
        :numeric
      end

      def foreign_key_link(label)
        url = property_model.viewable_url(id: value)
        url ? a_('.link.text-primary', text: label, href: url) : label
      end

      def property_model
        @property_model ||= self.class.association_for(section, property).klass.admin_model
      end
    end
  end
end
