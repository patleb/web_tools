module Admin
  module Fields
    module Association::AsArray
      extend ActiveSupport::Concern

      prepended do
        register_option :count? do
          false
        end

        register_option :array_separator do
          '<br>'.html_safe
        end

        register_option :array_bullet do
          '- '.html_safe
        end
      end

      def parse_input!(params)
        array? ? raise(NotImplementedError) : super
      end

      def parse_input(value)
        array? ? raise(NotImplementedError) : super
      end

      def parse_search(value)
        array? ? raise(NotImplementedError) : super
      end

      def format_value(value)
        return super if !array? || count?
        value = property_fields.map.with_index{ |field, i| super(value[i], field) }
        Admin::Field::AsArray.__call__(__method__, self, value)
      end

      def format_export(value)
        return super if !array? || count?
        value = property_fields.map.with_index{ |field, i| field.format_export(value[i]) }
        Admin::Field::AsArray.__call__(__method__, self, value)
      end

      def format_input(value)
        array? ? raise(NotImplementedError) : super
      end

      def value
        return property_count if count?
        array? ? property_fields.map(&:value) : super
      end

      def property_field
        array? ? property_fields.first : super
      end

      def property_fields
        memoize(self, __method__, bindings) do
          presenter[through].select_map do |record|
            field_for record
          end
        end
      end

      def property_count
        memoize(self, __method__, bindings) do
          next unless (model = property_model).allowed?
          presenter.associated_count(through, model)
        end
      end
    end
  end
end
