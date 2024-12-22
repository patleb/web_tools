# frozen_string_literal: true

module Admin
  module Fields
    class Association < Admin::Field
      delegate :foreign_key, :foreign_type, :polymorphic?, :list_parent?, :inverse_of, :nested_options, to: :property
      delegate :parse_input!, :parse_input, :parse_search, :format_export, :format_input, :value, to: :property_field, allow_nil: true

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
        return false unless nested?
        super && action.edit? && property_field
      end

      def type_css_class
        "#{super} association_type #{property_field&.type_css_class}"
      end

      def nested?
        !!nested_options
      end

      def array?
        false
      end

      def format_value(value, field = property_field)
        return unless (value = field&.format_value(value)).present?
        url = field.presenter.undiscarded? && field.presenter.viewable_url
        url ? a_('.link.text-primary', text: value, href: url) : value
      end

      def format_index(*)
        format_value(*)
      end

      def input_label
        if section.associations[through].size > 1 && as != property_model.primary_key.to_sym
          label = "#{klass.human_attribute_name(through)}: #{super}"
        else
          label = klass.human_attribute_name(through)
        end
        label.upcase_first.html_safe
      end

      def input_control
        raise NotImplementedError unless nested?
        property_field.input_control(**default_input_attributes)
      end

      def input_name
        raise NotImplementedError unless nested?
        as
      end

      def default_input_attributes
        raise NotImplementedError unless nested?
        property_field.default_input_attributes.merge!(through: through)
      end

      def property_field
        memoize(self, __method__, bindings) do
          field_for presenter[through]
        end
      end

      def property_model
        property.klass.admin_model
      end

      def property_name
        through
      end

      def column_name
        as
      end

      private

      def field_for(record)
        return unless record && (presenter = record.admin_presenter).allowed?
        ([section.name] + section.parent_names).find do |section_name|
          field = presenter.model.section(section_name).with(presenter: presenter).fields_hash[as]
          return field if field
        end
      end
    end
  end
end
