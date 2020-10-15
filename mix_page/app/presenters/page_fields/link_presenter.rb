module PageFields
  class LinkPresenter < TextPresenter
    delegate :view, :uuid, :to_url, :active, to: :object

    def viable_parent_names
      @viable_parent_names ||= (view&.split('/') || [])[0..-2].each_with_object([]) do |segment, names|
        names << [names.last, segment].compact.join('/')
      end.reverse
    end

    def node_name
      view
    end

    def dom_class
      super.push "link_#{view&.full_underscore}"
    end

    def html(only_text: false, sidebar: false, **options)
      options = options ? options.dup : {}
      url = to_url if active
      title = text.presence || pretty_blank
      css_classes = Array.wrap(options.delete(:class))
      css_classes << 'pjax' if url
      css_classes << 'inactive' unless active
      css_classes.concat(['js_sidebar', "js_sidebar_page_#{uuid}", "nav-level-#{level}"]) if sidebar
      if block_given?
        a_(href: url, class: css_classes, title: title, **options) { yield(title) }
      else
        a_(href: url, class: css_classes, title: title, **options) {[
          (pretty_actions(:span) unless only_text),
          i_('.fa.fa-chevron-down.js_sidebar_toggle', if: !only_text && sidebar && !editable? && !last?),
          span_{ title },
        ]}
      end
    end
  end
end
