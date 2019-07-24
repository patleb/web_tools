module ActionView::Helpers::TagHelper::TagBuilder::WithDataOption
  private

  def prefix_tag_option(prefix, key, value, escape)
    return super unless prefix.to_sym == :data

    unless value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(BigDecimal)
      value = value.to_json
    end
    tag_option("data-#{key}", value, escape)
  end
end

ActionView::Helpers::TagHelper::TagBuilder.prepend ActionView::Helpers::TagHelper::TagBuilder::WithDataOption
