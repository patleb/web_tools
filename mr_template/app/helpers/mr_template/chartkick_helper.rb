module MrTemplate
  module ChartkickHelper
    SUPPORTED_CHARTS = Set.new(%w(
      line
      pie
      column
      bar
      area
      scatter
      geo
      timeline
    ))

    def chartkick(type, data_source, **options)
      type = type.to_s
      raise "unsupported chart type [#{type}]" unless SUPPORTED_CHARTS.include?(type)

      @chartkick_chart_id ||= 0
      options = MrTemplate.config.chart_options.deep_merge(options)
      element_id = options.delete(:id) || "chart-#{@chartkick_chart_id += 1}"
      height = ERB::Util.html_escape(options.delete(:height) || "300px")
      width = ERB::Util.html_escape(options.delete(:width) || "100%")
      createjs = {
        type: "#{type.camelize}#{'Chart' unless type == 'timeline'}",
        id: element_id,
        source: data_source.respond_to?(:chart) ? data_source.chart : data_source,
        options: options,
      }
      preload_html = options.delete(:html)
      preload_html ||=
        div_('Loading...', id: element_id,
          style: "height: #{height}; width: #{width}; text-align: center; color: #999; line-height: #{height}; "\
                 "font-size: 14px; font-family: 'Lucida Grande', 'Lucida Sans Unicode', Verdana, Arial, Helvetica, sans-serif;"
        )
      h_(
        preload_html,
        div_('.js_chartkick_config', data: { config: createjs })
      )
    end
  end
end
