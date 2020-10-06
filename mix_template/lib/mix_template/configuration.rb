module MixTemplate
  has_config do
    attr_writer :parent_controller
    attr_writer :web_app_capable
    attr_writer :version
    attr_writer :version_path
    attr_writer :chart_options

    def parent_controller
      @parent_controller ||= '::ActionController::Base'
    end

    def web_app_capable
      return @web_app_capable if defined? @web_app_capable
      @web_app_capable = true
    end

    def version
      @version ||= version_path.exist? ? version_path.read.first(7) : '0.1.0'
    end

    def version_path
      @version_path ||= Rails.root.join('REVISION')
    end

    def chart_options
      @chart_options ||= {
        responsive: true,
        height: '360px',
      }
    end
  end
end
