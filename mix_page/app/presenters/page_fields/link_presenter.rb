module PageFields
  class LinkPresenter < TextPresenter
    delegate :view, :uuid, :to_url, to: :object

    def dom_class
      super.push "link_#{view&.full_underscore}"
    end

    def html(**options)
      options = options ? options.dup : {}
      title = text.presence || pretty_blank
      css_classes = ['js_page_link', "js_page_link_model_#{uuid}", ('pjax' if url), options.delete(:class)]
      a_(href: url, class: css_classes, title: title, **options) {[
        pretty_actions(:span),
        title,
      ]}
    end

    def url
      return @url if defined? @url
      @url = to_url
    end

    def parent_link
      return unless (parts = view&.split('/') || []).size > 1

    end
  end
end
