module PageFields
  class LinkPresenter < TextPresenter
    def dom_class
      super.push "link_#{object.view&.full_underscore}"
    end

    def html(**options)
      options = options ? options.dup : {}
      title = text.presence || pretty_blank
      css_classes = ['js_page_link', "js_page_link_model_#{object.uuid}", ('pjax' if url), options.delete(:class)]
      a_(href: url, class: css_classes, title: title, **options) {[
        pretty_actions(:span),
        title,
      ]}
    end

    def url
      return @url if defined? @url
      @url = object.to_url
    end
  end
end
