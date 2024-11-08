# frozen_string_literal: true

module Admin
  module Fields
    class Association < Admin::Field
      autoload :AsArray, prepend: true

      delegate :foreign_key, :foreign_type, :polymorphic?, :list_parent?, :inverse_of, :nested_options, to: :property
      delegate :parse_input!, :parse_input, :parse_search, :format_export, :format_input, :value, to: :property_field, allow_nil: true

      register_option :label do
        if section.associations[through].size > 1 && as != property_model.primary_key.to_sym
          label = "#{klass.human_attribute_name(through)}: #{__super__ :label}"
        else
          label = klass.human_attribute_name(through)
        end
        label.upcase_first.html_safe
      end

      register_option :queryable do
        as if eager_load
      end

      # NOTE instance dependent scope isn't supported
      register_option :eager_load do
        through if property.reflection.scope&.arity.to_i == 0
      end

      register_option :left_joins do
        false
      end

      register_option :distinct? do
        false
      end

      register_option :include_blank? do
        true
      end

      def allowed_field?
        super && property_model.allowed?
      end

      def editable?
        super && action.edit? && nested?
      end

      def type_css_class
        "#{super} association_type #{column_field&.type_css_class}"
      end

      def nested?
        !!nested_options
      end

      def format_value(value, field = property_field)
        return unless (value = field&.format_value(value)).present?
        url = field.presenter.undiscarded? && field.presenter.viewable_url
        url ? a_('.link.text-primary', text: value, href: url) : value
      end

      def input_name
        nested? ? as : super
      end

      def default_input_attributes
        nested? ? super.merge!(through: through) : super
      end

      def property_field
        memoize(self, __method__, bindings) do
          if (record = presenter[through]) && (presenter = record.admin_presenter).allowed?
            column_field.with(presenter: presenter)
          end
        end
      end

      def property_model
        property.klass.admin_model
      end

      def property_name
        through
      end

      def column_field
        property_model.section(section.name).fields_hash[as]
      end

      def column_name
        as
      end
    end
  end
end
