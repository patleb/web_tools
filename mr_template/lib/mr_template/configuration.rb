module MrTemplate
  has_config do
    attr_writer :html_extra_tags
    attr_writer :version
    attr_writer :version_path
    attr_writer :chart_options

    def html_extra_tags
      @html_extra_tags ||= []
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
