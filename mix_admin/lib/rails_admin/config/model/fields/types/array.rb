class RailsAdmin::Config::Model::Fields::Array < RailsAdmin::Config::Model::Fields::Base
  autoload_dir RailsAdmin::Engine.root.join('lib/rails_admin/config/model/fields/types/array')

  register_instance_option :pretty_value do
    if array_separator
      if array_bullet
        value = safe_join(pretty_array, array_separator + array_bullet)
        value = array_bullet + value if value.present?
        value
      else
        safe_join(pretty_array, array_separator)
      end
    else
      to_sentence(pretty_array)
    end
  end

  register_instance_option :index_value do
    if array_separator
      truncated_array
    elsif truncated?
      truncated_value
    else
      pretty_value
    end
  end

  register_instance_option :export_value do
    if array_bullet
      value = export_array&.join("\n#{array_bullet}")
      value = "#{array_bullet}#{value}" if value.present?
      value
    else
      export_array&.join("\n")
    end
  end

  register_instance_option :readonly?, memoize: true do
    true
  end

  register_instance_option :truncated?, memoize: true do
    true
  end

  register_instance_option :array_bullet, memoize: true do
    nil
  end

  def array?
    true
  end

  def virtual?
    true
  end

  def array_separator
    nil
  end

  # TODO use formatted_value
  def pretty_array
    value.try(:compact) || value || []
  end

  def export_array
    value
  end

  def truncated_array_options
    nil
  end

  def truncated_array(value = pretty_value, options = truncated_array_options)
    return value unless value.present?
    separator = array_separator
    if (n = options[:max_items].to_i) > 0
      if (length = value.index_n(separator, n))
        length += array_bullet&.size.to_i
      else
        length = value.size
      end
    elsif (length = value.index(separator))
      length += array_bullet&.size.to_i
      if length > section.truncate_length
        length = section.truncate_length
        separator = ' '
      end
    else
      length = section.truncate_length
    end
    value = truncated_value(value, truncated_value_options.merge!(length: length, separator: separator, **options))
    value = value.html_safe unless options[:escape]
    value
  end
end
