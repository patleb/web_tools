module Admin
  module Fields
    module Association::AsArray
      extend ActiveSupport::Concern

      prepended do
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

      def parse_search(value)
        array? ? raise(NotImplementedError) : super
      end

      def parse_value(value)
        array? ? raise(NotImplementedError) : super
      end

      def format_value(value)
        return super unless array?
        value = property_fields.map.with_index{ |field, i| super(value[i], field) }
        Admin::Field::AsArray.__call__(__method__, self, value)
      end

      def format_input(value)
        array? ? raise(NotImplementedError) : super
      end

      def format_export(value)
        return super unless array?
        value = property_fields.map.with_index{ |field, i| field.format_export(value[i]) }
        Admin::Field::AsArray.__call__(__method__, self, value)
      end

      def value
        array? ? property_fields.map(&:value) : super
      end

      def property_fields
        memoize(self, __method__, bindings) do
          field = column_field
          presenter[through].select_map do |record|
            next unless (presenter = record.admin_presenter).allowed?
            field.with(presenter: presenter)
          end
        end
      end
    end
  end
end
