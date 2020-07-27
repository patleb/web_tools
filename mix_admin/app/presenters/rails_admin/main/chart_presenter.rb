module RailsAdmin::Main
  class ChartPresenter < BasePresenter
    delegate :refresh_rate, to: :main_section

    def render
      options = {}
      source =
        if request.variant.chart?
          if chart_form[:auto_refresh].to_b
            options[:refresh] = refresh_rate
          end
          path_params = params.permit(:model_name, :scope, :query, f: {}, c: {})
          path_params = path_params.merge(all: true, chart: true, chart_form: chart_form_defaults)
          chart_path(path_params.with_keyword_access)
        else
          []
        end
      chartkick main_section.type, source, main_section.options.merge(options)
    end

    def field_options
      result = {}
      main_fields.select{ |f| !f.association? || f.polymorphic? }.each do |field|
        list = field.virtual? ? 'methods' : 'only'
        if field.association? && field.polymorphic?
          result["#{field.label} [id]"] = "schema[#{list}][#{field.method_name}]"
          polymorphic_type_column_name = @abstract_model.columns.find{ |c| field.property.foreign_type == c.name }.name
          result["#{field.label.upcase_first} [type]"] = "schema[#{list}][#{polymorphic_type_column_name}]"
        else
          result[field.label.upcase_first] = "schema[#{list}][#{field.name}]"
        end
      end
      main_fields.select{ |f| f.association? && !f.polymorphic? }.each do |field|
        field.associated_model.chart.visible_fields.reject(&:association?).each do |associated_model_field|
          list = associated_model_field.virtual? ? 'methods' : 'only'
          # TODO bug --> it overrides non-associations with the same name
          result[associated_model_field.label.upcase_first] = "schema[include][#{field.name}][#{list}][#{associated_model_field.name}]"
        end
      end
      options_for_select(result, field_default)
    end

    def calculation_options
      options_for_select(%i[
        count
        average
        minimum
        maximum
        sum
      ], calculation_default)
    end

    def field_default
      chart_form[:field] || begin
        field_name = main_section.field_default
        if field_name
          field = chart_field_for(field_name)
          "schema[#{field.virtual? ? 'methods' : 'only'}][#{field_name}]"
        end
      end
    end

    def calculation_default
      chart_form[:calculation] || :average
    end

    def auto_refresh_default
      chart_form[:auto_refresh].to_b
    end

    def chart_form_path
      chart_path(params.permit(:model_name, :scope).merge(all: true).with_keyword_access)
    end

    def ordered_charts
      @_ordered_charts ||= (params[:c]&.to_unsafe_h || {}).to_a.sort_by(&:first).each_with_object({}) do |(index, inputs), memo|
        inputs.each do |(name, value)|
          case name.to_sym
          when :field
            field = chart_field_for(value.match(/\[(\w+)\]$/)[1])
            label_name = t('admin.chart.field')
            label_value = field.label
          when :calculation
            label_name = t('admin.chart.calculation')
            label_value = value
          else
            field = chart_field_for(value)
            label_name = field.label
            label_value = value.to_s
          end
          memo[index] ||= []
          memo[index] << {
            index: index,
            input: { name: name, value: value },
            label: { name: label_name, value: label_value }
          }
        end
      end
    end

    private

    def chart_field_for(name)
      main_fields.find{ |f| f.name == name.to_sym }
    end

    def chart_form_defaults
      {
        field: field_default,
        calculation: calculation_default,
        auto_refresh: auto_refresh_default,
      }
    end

    def chart_form
      @_chart_form ||= params[:chart_form] || {}
    end
  end
end
