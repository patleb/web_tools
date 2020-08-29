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

  def page_presenter(key, type = nil, create: true, layout: false, multi: false)
    if (result = (@_memoized ||= {}).dig(key, type, create, layout, multi)).nil?
      result = ((((@_memoized[key] ||= {})[type] ||= {})[create] ||= {})[layout] ||= {})[multi] = begin
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
          fields = [scope.page_fields.create!(type: type || DEFAULT_TYPE, key: key)] if fields.empty? && create
          if fields.map!(&:presenter).any?
            list_presenter_class = type && "#{type}ListPresenter".to_const
            list_presenter_class ||= "#{fields.first.object.class.base_class.name}".to_const!
            list_presenter_class.new(list: fields)
          else
            false
          end
        else
          field = scope.page_fields.find(&filter)
          field = scope.page_fields.create!(type: type || DEFAULT_TYPE, key: key) if field.nil? && create
          field&.presenter || false
        end
      end
    end
    result == false ? nil : result
  end
end
