module PagesHelper
  class TypeAlreadyInUse < StandardError; end

  TYPES_MAPPING = MixPage.config.available_field_types.keys.each_with_object({}) do |name, types|
    type = name.demodulize.underscore
    raise TypeAlreadyInUse if types.has_key? type
    types[type] = name
  end

  # For the type PageFields::Link, method_missing could define the following helpers:
  # ----
  # layout_link_presenters(name)
  # layout_link_presenter(name)
  # ----
  # page_link_presenters(name)
  # page_link_presenter(name)
  # ----
  # layout_links(name, list_options = {}, item_options = {}, &block)
  # layout_link(name, item_options = {})
  # ----
  # page_links(name, list_options = {}, item_options = {}, &block)
  # page_link(name, item_options = {})
  #
  def method_missing(name, *args, &block)
    if (options = page_helper_options(name))
      type = TYPES_MAPPING[options.delete(:type)]
      if options.delete(:render)
        if options[:multi]
          self.class.send(:define_method, name) do |name, list_options = {}, item_options = {}, &block|
            page_presenter(name, type, **options)&.render(list_options, item_options, &block)
          end
        else
          self.class.send(:define_method, name)do |name, **item_options|
            page_presenter(name, type, **options)&.render(**item_options)
          end
        end
      else
        self.class.send(:define_method, name) do |name|
          page_presenter(name, type, **options)
        end
      end
      send(name, *args, &block)
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

  def page_presenter(name, type, layout: false, multi: false) # TODO allow multiple types
    return unless @page && type.in?(page_field_types)
    name = name.to_s
    (((((@memoized ||= {})[:page_presenter] ||= {})[name] ||= {})[type] ||= {})[layout] ||= {})[multi] ||= begin
      scope = layout ? @page.layout : @page
      filter = ->(field) { field.type == type && field.name == name && field.show? }
      if multi
        fields = scope.page_fields.select(&filter)
        fields = [scope.page_fields.create!(type: type, name: name)] if fields.empty?
        fields.map!(&:presenter)
        list_presenter_class = type && "#{type}ListPresenter".to_const
        list_presenter_class ||= "#{fields.first.object.class.superclass.name}ListPresenter".to_const
        list_presenter_class ||= "#{fields.first.object.class.base_class.name}ListPresenter".to_const!
        list_presenter_class.new(page_id: scope.id, types: [type], list: fields)
      else
        field = scope.page_fields.find(&filter)
        field = scope.page_fields.create!(type: type, name: name) if field.nil?
        field.presenter
      end
    end
  end

  def page_paginate(name)
    div_(".page_paginate.page_paginate_#{name}") do
      [page_prev(name), page_next(name)].compact.join(' | ').html_safe
    end
  end

  def page_next(name)
    page_next_presenter(name)&.render(class: ['page_next']) {[
      span_{ t('page_paginate.next') },
      i_('.fa.fa-chevron-circle-right')
    ]}
  end

  def page_prev(name)
    page_prev_presenter(name)&.render(class: ['page_prev']) {[
      i_('.fa.fa-chevron-circle-left'),
      span_{ t('page_paginate.prev') }
    ]}
  end

  def page_next_presenter(name)
    with_layout_links(name) do |links, index|
      links[(index + 1)..-1].find(&:active)
    end
  end

  def page_prev_presenter(name)
    with_layout_links(name) do |links, index|
      links[0..(index - 1)].reverse.find(&:active) if index > 0
    end
  end

  def preview_link
    if defined?(MixAdmin) && Current.controller.try(:pages?)
      if Current.user_role?
        a_ href: "?_user_role=false" do
          span_ '.label.label-danger', t('user.quit_preview')
        end
      elsif Current.user.admin?
        a_ href: "?_user_role=true" do
          span_ '.label.label-primary', t('user.enter_preview')
        end
      end
    end
  end

  private

  def page_field_types
    @page_field_types ||= MixPage.config.available_field_types.keys.select{ |type| can? :create, type }
  end

  def with_layout_links(name)
    links = layout_link_presenters(name)&.list || []
    index = links.index{ |presenter| presenter.object.fieldable_id == @page.id } || links.size
    yield(links, index)
  end
end
