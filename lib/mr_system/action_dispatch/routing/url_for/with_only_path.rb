module ActionDispatch::Routing::UrlFor::WithOnlyPath
  def url_for(options = nil)
    return super unless options.is_a? Hash

    options = options.symbolize_keys
    unless options.key?(:only_path)
      unless options.key?(:host)
        options[:only_path] = true
      end
    end

    super(options)
  end
end

ActionDispatch::Routing::UrlFor.prepend ActionDispatch::Routing::UrlFor::WithOnlyPath
