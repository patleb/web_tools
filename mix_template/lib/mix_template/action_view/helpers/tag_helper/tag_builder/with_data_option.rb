module ActionView::Helpers::TagHelper::TagBuilder::WithDataOption
  private

  def prefix_tag_option(prefix, key, value, escape)
    return super unless prefix.to_sym == :data

    case value
    when String, Symbol, Numeric, Boolean
    else value = value.to_json
    end
    tag_option("data-#{key}", value, escape)
  end
end

ActionView::Helpers::TagHelper::TagBuilder.prepend ActionView::Helpers::TagHelper::TagBuilder::WithDataOption
