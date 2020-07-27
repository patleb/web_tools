class RailsAdmin::Config::Model::Fields::Enum < RailsAdmin::Config::Model::Fields::Base
  require_rel 'enum'

  include self::Formatter

  register_instance_option :render do
    collection = enum
    selected = form_value
    div_ class: bs_form_row do
      if multiple?
        values, texts = collection.each_with_object([[], []]) do |(text, value), memo|
          memo[0] << (value || text)
          memo[1] << text
        end
        form.select(method_name, collection, { include_blank: include_blank?, selected: selected, object: form.object },
          html_attributes.reverse_merge(
            class: "js_field_input js_select_multi form-control", multiple: true,
            data: { config: {
              required: required?, include_blank: include_blank?, selected: selected, values: values, texts: texts }
            }
          )
        )
      else
        form.select(method_name, collection, { include_blank: include_blank?, selected: selected },
          html_attributes.reverse_merge(class: 'form-control')
        )
      end
    end
  end

  register_instance_option :include_blank?, memoize: :locale do
    enum.to_a.map(&:last).none?(&:blank?)
  end

  register_instance_option :pretty_value do
    pretty_format_enum(value)
  end

  register_instance_option :multiple? do
    property && [:serialized].include?(property.type)
  end

  def parse_value(value)
    return unless value.present?
    case (type = klass.attribute_types[name.to_s])
    when ActiveModel::Type::Integer
      value if value.to_i?
    else
      value
    end
  end
end
