module PageHelper
  class PageHelperAlreadyDefined < StandardError; end

  DEFAULT_TYPE = 'PageFields::Text'

  MixPage.config.available_field_types.each_key do |type|
    field = type.demodulize.underscore

    raise PageHelperAlreadyDefined if respond_to? "layout_#{field}s"
    define_method "layout_#{field}s" do |name, **options|
      layout_presenters(name, type, **options)&.render
    end

    raise PageHelperAlreadyDefined if respond_to? "layout_#{field}"
    define_method "layout_#{field}" do |name, **options|
      layout_presenter(name, type, **options)&.render
    end

    raise PageHelperAlreadyDefined if respond_to? "page_#{field}s"
    define_method "page_#{field}s" do |name, **options|
      page_presenters(name, type, **options)&.render
    end

    raise PageHelperAlreadyDefined if respond_to? "page_#{field}"
    define_method "page_#{field}" do |name, **options|
      page_presenter(name, type, **options)&.render
    end
  end

  def layout_presenters(*args, **options)
    layout_presenter(*args, **options, multi: true)
  end

  def layout_presenter(*args, **options)
    page_presenter(*args, **options, layout: true)
  end

  def page_presenters(*args, **options)
    page_presenter(*args, **options, multi: true)
  end

  def page_presenter(name, type = nil, layout: false, multi: false)
    return unless @page
    (((((@memoized ||= {})[:page_presenter] ||= {})[name] ||= {})[type] ||= {})[layout] ||= {})[multi] ||= begin
      scope = layout ? @page.layout : @page
      filter = ->(field) { (!type || field.type == type) && field.name == name }
      if multi
        fields = scope.page_fields.select(&filter)
        fields = [scope.page_fields.create!(type: type || DEFAULT_TYPE, name: name)] if fields.empty?
        fields.map!(&:presenter)
        list_presenter_class = type && "#{type}ListPresenter".to_const
        list_presenter_class ||= "#{fields.first.object.class.superclass.name}ListPresenter".to_const
        list_presenter_class ||= "#{fields.first.object.class.base_class.name}ListPresenter".to_const!
        list_presenter_class.new(page_id: scope.id, type: type, list: fields)
      else
        field = scope.page_fields.find(&filter)
        field = scope.page_fields.create!(type: type || DEFAULT_TYPE, name: name) if field.nil?
        field.presenter
      end
    end
  end
end
