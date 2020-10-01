module PageHelper
  class PageHelperAlreadyDefined < StandardError; end

  MixPage.config.available_field_types.each_key do |type|
    field = type.demodulize.underscore

    raise PageHelperAlreadyDefined if respond_to? "layout_#{field}s"
    define_method "layout_#{field}s" do |name, list_options = {}, item_options = {}, &block|
      layout_presenters(name, type)&.render(list_options, item_options, &block)
    end

    raise PageHelperAlreadyDefined if respond_to? "layout_#{field}"
    define_method "layout_#{field}" do |name, **item_options|
      layout_presenter(name, type)&.render(**item_options)
    end

    raise PageHelperAlreadyDefined if respond_to? "page_#{field}s"
    define_method "page_#{field}s" do |name, list_options = {}, item_options = {}, &block|
      page_presenters(name, type)&.render(list_options, item_options, &block)
    end

    raise PageHelperAlreadyDefined if respond_to? "page_#{field}"
    define_method "page_#{field}" do |name, **item_options|
      page_presenter(name, type)&.render(**item_options)
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
    return unless @page && type.in?(page_field_types)
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

  private

  def page_field_types
    @page_field_types ||= MixPage.config.available_field_types.keys.select{ |type| can? :create, type }
  end
end
