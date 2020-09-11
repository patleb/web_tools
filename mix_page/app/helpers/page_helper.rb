module PageHelper
  class InvalidVirtualPath < StandardError; end

  DEFAULT_TYPE = 'PageFieldText'

  MixPage.config.available_fields.each_key do |type|
    if type.start_with? 'PageField'
      field = type.delete_prefix('PageField').full_underscore
    else
      next
    end

    define_method "layout_#{field}_presenters" do |name, **options|
      layout_presenters(name, type, **options)
    end

    define_method "layout_#{field}_presenter" do |name, **options|
      layout_presenter(name, type, **options)
    end

    define_method "page_#{field}_presenters" do |name, **options|
      page_presenters(name, type, **options)
    end

    define_method "page_#{field}_presenter" do |name, **options|
      page_presenter(name, type, **options)
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
    (((((@memoized ||= {})[:page_presenter] ||= {})[name] ||= {})[type] ||= {})[layout] ||= {})[multi] ||= begin
      scope = @page.layout if layout
      scope ||=
        case @virtual_path
        when @page.layout.view, "#{@page.layout.view}/pjax"
          @page.layout
        when @page.view
          @page
        else
          raise InvalidVirtualPath
        end
      filter = ->(field) { (!type || field.type == type) && field.name == name }
      if multi
        fields = scope.page_fields.select(&filter)
        fields = [scope.page_fields.create!(type: type || DEFAULT_TYPE, name: name)] if fields.empty?
        fields.map!(&:presenter)
        list_presenter_class = type && "#{type}ListPresenter".to_const
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
