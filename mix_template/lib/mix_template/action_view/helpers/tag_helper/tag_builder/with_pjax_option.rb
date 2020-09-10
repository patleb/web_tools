module ActionView::Helpers::TagHelper::TagBuilder::WithPjaxOption
  PJAX_FORM_TAGS = %w(button select textarea input).freeze
  PJAX_LINK_CLASS = /(^| )pjax( |$)/.freeze
  PJAX_READY_CLASS = 'pjax_ready'.freeze

  def tag_string(name, content = nil, escape_attributes: true, **options, &block)
    pjax! name, options
    super
  end

  def content_tag_string(name, content, options, escape = true)
    pjax! name, options
    super
  end

  private

  def pjax!(name, options)
    options.symbolize_keys!
    if pjax? && (PJAX_FORM_TAGS.include?(name.to_s) || options[:class]&.match?(PJAX_LINK_CLASS))
      options[:class] = options[:class] ? options[:class].to_s << ' ' : ''
      options[:class] << PJAX_READY_CLASS
    end
  end

  def pjax?
    (@view_context.instance_variable_get(:@template_object) || @view_context).try(:pjax?)
  end
end

ActionView::Helpers::TagHelper::TagBuilder.prepend ActionView::Helpers::TagHelper::TagBuilder::WithPjaxOption
