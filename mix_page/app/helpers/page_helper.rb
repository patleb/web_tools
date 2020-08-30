module PageHelper
  DEFAULT_TYPE = 'PageFieldText'

  MixPage.config.available_fields.each_key do |type|
    if type.start_with? 'PageField'
      name = type.sub(/^PageField/, 'Page').full_underscore
    else
      next
    end

    define_method "layout_#{name}_presenters" do |key, **options|
      layout_presenters(key, type, **options)
    end

    define_method "layout_#{name}_presenter" do |key, **options|
      layout_presenter(key, type, **options)
    end

    define_method "page_#{name}_presenters" do |key, **options|
      page_presenters(key, type, **options)
    end

    define_method "page_#{name}_presenter" do |key, **options|
      page_presenter(key, type, **options)
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

  def page_presenter(key, type = nil, layout: false, multi: false)
    (((((@memoized ||= {})[:page_presenter] ||= {})[key] ||= {})[type] ||= {})[layout] ||= {})[multi] ||= begin
      scope = @page.layout if layout
      scope ||=
        case @virtual_path
        when @page.layout.view, "#{@page.layout.view}/pjax"
          @page.layout
        when @page.view
          @page
        end
      filter = ->(field) { (!type || field.type == type) && field.key == key }
      if multi
        fields = scope.page_fields.select(&filter)
        fields = [scope.page_fields.create!(type: type || DEFAULT_TYPE, key: key)] if fields.empty?
        fields.map!(&:presenter)
        list_presenter_class = type && "#{type}ListPresenter".to_const
        list_presenter_class ||= "#{fields.first.object.class.base_class.name}ListPresenter".to_const!
        list_presenter_class.new(type: type, list: fields)
      else
        field = scope.page_fields.find(&filter)
        field = scope.page_fields.create!(type: type || DEFAULT_TYPE, key: key) if field.nil?
        field.presenter
      end
    end
  end
end
