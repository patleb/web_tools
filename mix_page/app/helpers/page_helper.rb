module PageHelper
  DEFAULT_TYPE = 'PageFieldText'

  MixPage.config.available_fields.each_key do |type|
    if type.start_with? 'PageField'
      name = type.sub(/^PageField/, 'Page').full_underscore
    else
      next
    end

    define_method "layout_#{name}_presenters" do |key, **options|
      layout_presenters(key, **options, type: type)
    end

    define_method "layout_#{name}_presenter" do |key, **options|
      layout_presenter(key, **options, type: type)
    end

    define_method "page_#{name}_presenters" do |key, **options|
      page_presenters(key, **options, type: type)
    end

    define_method "page_#{name}_presenter" do |key, **options|
      page_presenter(key, **options, type: type)
    end
  end

  def layout_presenters(key, **options)
    layout_presenter(key, **options, multi: true)
  end

  def layout_presenter(key, **options)
    page_presenter(key, **options, layout: true)
  end

  def page_presenters(key, **options)
    page_presenter(key, **options, multi: true)
  end

  def page_presenter(key, type: nil, create: true, layout: false, multi: false)
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
      if fields.empty? && create
        fields = [scope.page_fields.create!(type: type || DEFAULT_TYPE, key: key)]
      end
      unless fields.map!(&:presenter).empty?
        type_name = type || fields.first.object.class.base_class.name
        ActiveSupport::Dependencies.constantize("#{type_name}ListPresenter").new(list: fields)
      end
    else
      field = scope.page_fields.find(&filter)
      if field.nil? && create
        field = scope.page_fields.create! type: type || DEFAULT_TYPE, key: key
      end
      field&.presenter
    end
  end
end
