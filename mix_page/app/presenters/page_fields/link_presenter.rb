module PageFields
  class LinkPresenter < TextPresenter
    delegate :view, :uuid, :to_url, to: :object

    def dom_class
      super.push "link_#{view&.full_underscore}"
    end

    def parent_name
      return @parent_name if defined? @parent_name
      @parent_name = view&.include?('/') ? view.sub(%r{/\w+$}, '') : super
    end

    def node_name
      view || super
    end

    def html(sidebar: false, **options)
      options = options ? options.dup : {}
      url = to_url
      title = text.presence || pretty_blank
      css_classes = Array.wrap(options.delete(:class))
      css_classes << 'pjax' if url
      css_classes.concat(['js_sidebar', "js_sidebar_page_#{uuid}", "nav-level-#{level}"]) if sidebar
      a_(href: url, class: css_classes, title: title, **options) {[
        pretty_actions(:span),
        i_('.fa.fa-chevron-down.js_sidebar_toggle', if: sidebar && !last?),
        title,
      ]}
    end
  end
end
