class RailsAdmin::Config::Model::Fields::String < RailsAdmin::Config::Model::Fields::Base
  register_instance_option :truncated?, memoize: true do
    true
  end

  register_instance_option :html_attributes do
    {
      required: required?,
      maxlength: max_length,
      size: input_size,
    }
  end

  def input_size
    [50, length.to_i].reject(&:zero?).min
  end

  def max_length
    [length, valid_length[:maximum] || nil].compact.min
  end

  def min_length
    [0, valid_length[:minimum] || nil].compact.max
  end

  def generic_help
    text = (required? ? I18n.t('admin.form.required') : I18n.t('admin.form.optional')) + '. '
    if valid_length.present? && valid_length[:is].present?
      text += "#{I18n.t('admin.form.char_length_of').capitalize} #{valid_length[:is]}."
    else
      max, min = max_length, min_length
      if max
        text +=
          if min == 0
            "#{I18n.t('admin.form.char_length_up_to').capitalize} #{max}."
          else
            "#{I18n.t('admin.form.char_length_of').capitalize} #{min}-#{max}."
          end
      end
    end
    text
  end
end
