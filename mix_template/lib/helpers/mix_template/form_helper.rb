module MixTemplate
  module FormHelper
    def form_tag(url_for_options = {}, options = {}, &block)
      if block_given?
        super(url_for_options, options) do
          h_(&block)
        end
      else
        super
      end
    end

    def form_for(record, options = {}, &block)
      super(record, options) do
        h_(&block)
      end
    end

    def form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
      if block_given?
        super(model: model, scope: scope, url: url, format: format, **options) do
          h_(&block)
        end
      else
        super
      end
    end

    def fields_for(record_name, record_object = nil, options = {}, &block)
      super(record_name, record_object, options) do
        h_(&block)
      end
    end

    def fields(scope = nil, model: nil, **options, &block)
      super(scope, model: model, **options) do
        h_(&block)
      end
    end

    def label(object_name, method, content_or_options = nil, options = nil, &block)
      if block_given?
        super(object_name, method, content_or_options, options) do
          h_(&block)
        end
      else
        super
      end
    end
  end
end
