module PageHelper
  class TypeAlreadyInUse < StandardError; end

  TYPES_MAPPING = MixPage.config.available_field_types.keys.each_with_object({}) do |name, types|
    type = name.demodulize.underscore
    raise TypeAlreadyInUse if types.has_key? type
    types[type] = name
  end

  def website_link
    return unless website_link?
    li_ do
      a_ '.website_link', [icon('layout-text-sidebar-reverse'), t('link.website')], href: pages_root_path
    end
  end

  def website_link?
    !Current.controller.is_a?(PagesController)
  end

  def page_sidebar(**, &)
    layout_links(:sidebar, list_tag: 'ul', item_tag: 'li', divider: true, **, &)
  end

  def page_content(**, &)
    page_html(:content, **, &)
  end

  def pagination(**)
    PaginationPresenter.render(**)
  end

  # For the type PageFields::Link, method_missing could define the following helpers:
  # ----
  # layout_link_presenters(name)
  # layout_link_presenter(name)
  # ----
  # page_link_presenters(name)
  # page_link_presenter(name)
  # ----
  # layout_links(name, item_options: {}, **list_options, &block)
  # layout_link(name, **item_options, &block)
  # ----
  # page_links(name, item_options: {}, **list_options, &block)
  # page_link(name, **item_options, &block)
  #
  def method_missing(helper_name, ...)
    if (options = page_helper_options(helper_name))
      type = TYPES_MAPPING[options.delete(:type)]
      if options.delete(:render)
        if options[:multi]
          self.class.define_method(helper_name) do |name, **multi_options, &block|
            page_presenter(name, type, **options).render(**multi_options, &block)
          end
        else
          self.class.define_method(helper_name) do |name, **item_options, &block|
            page_presenter(name, type, **options).render(**item_options, &block)
          end
        end
      else
        self.class.define_method(helper_name) do |name|
          page_presenter(name, type, **options)
        end
      end
      send(helper_name, ...)
    else
      super
    end
  end

  def respond_to_missing?(name, _include_private = false)
    !!page_helper_options(name) || super
  end

  def page_helper_options(name)
    type = name.to_s.dup
    layout = !!type.delete_prefix!('layout_')
    if layout || type.delete_prefix!('page_')
      case
      when type.delete_suffix!('_presenters') then multi = true;  render = false
      when type.delete_suffix!('_presenter')  then multi = false; render = false
      when type.delete_suffix!('s')           then multi = true;  render = true
      else                                         multi = false; render = true
      end
      { type: type, layout: layout, multi: multi, render: render } if TYPES_MAPPING.has_key? type
    end
  end

  def layout_presenters(*args)
    page_presenter(*args, layout: true, multi: true)
  end

  def layout_presenter(*args)
    page_presenter(*args, layout: true, multi: false)
  end

  def page_presenters(*args)
    page_presenter(*args, layout: false, multi: true)
  end

  def page_presenter(name, type, layout: false, multi: false)
    return unless @page
    name = name.to_sym
    ((((@page_presenters ||= {})[name] ||= {})[type] ||= {})[layout] ||= {})[multi] ||= begin
      scope = layout ? @page.layout : @page
      filter = ->(field) { field.type == type && field.name == name && field.show? }
      if multi
        fields = scope.page_fields.select(&filter)
        fields = [scope.page_fields.create!(type: type, name: name)] if fields.empty?
        fields.map!(&:presenter)
        fields.list_presenter(page_id: scope.id)
      else
        field = scope.page_fields.find(&filter)
        field = scope.page_fields.create!(type: type, name: name) if field.nil?
        field.presenter
      end
    end
  end
end
