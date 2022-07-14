module MixTemplate
  has_config do
    attr_writer :parent_controller
    attr_writer :web_app_capable
    attr_writer :theme
    attr_writer :katex_version
    attr_writer :chart_options

    def parent_controller
      @parent_controller ||= 'ActionController::Base'
    end

    def web_app_capable
      return @web_app_capable if defined? @web_app_capable
      @web_app_capable = true
    end

    def theme
      @theme ||= :paper
    end

    def katex_version
      @katex_version ||= '0.12.0'
    end

    def chart_options
      @chart_options ||= {
        responsive: true,
        height: '360px',
      }
    end
  end
end
