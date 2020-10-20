module TemplatesHelper
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
    options = MixTemplate.config.chart_options.deep_merge(options)
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

  def body_id
    [current_layout, 'layout'].compact.join('_').full_underscore.sub('_pjax_', '_')
  end

  def body_class
    [template_virtual_path, 'template'].compact.join('_').full_underscore
  end

  def current_layout
    @_current_layout ||= begin
      layout_controller = is_a?(ActionController::Base) ? self : controller
      layout_path = layout_controller.send(:_layout, @lookup_context || @_lookup_context, [:html])
      (layout_path.is_a?(String) ? layout_path : layout_path.virtual_path).delete_prefix('layouts/')
    end
  end

  def query_diet(**options)
    query_diet_widget(options) if defined? QueryDiet
  end

  def template_status_css
    style_(type: 'text/css') do
      <<~CSS.html_safe
        .rails-default-error-page {
          background-color: #EFEFEF;
          color: #2E2F30;
          text-align: center;
          font-family: arial, sans-serif;
          margin: 0;
        }

        .rails-default-error-page div.dialog {
          width: 95%;
          max-width: 33em;
          margin: 4em auto 0;
        }

        .rails-default-error-page div.dialog > div {
          border: 1px solid #CCC;
          border-right-color: #999;
          border-left-color: #999;
          border-bottom-color: #BBB;
          border-top: #B00100 solid 4px;
          border-top-left-radius: 9px;
          border-top-right-radius: 9px;
          background-color: white;
          padding: 7px 12% 0;
          box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
        }

        .rails-default-error-page h1 {
          font-size: 100%;
          color: #730E15;
          line-height: 1.5em;
        }

        .rails-default-error-page div.dialog > p {
          margin: 0 0 1em;
          padding: 1em;
          background-color: #F7F7F7;
          border: 1px solid #CCC;
          border-right-color: #999;
          border-left-color: #999;
          border-bottom-color: #999;
          border-bottom-left-radius: 4px;
          border-bottom-right-radius: 4px;
          border-top-color: #DADADA;
          color: #666;
          box-shadow: 0 3px 8px rgba(50, 50, 50, 0.17);
        }
      CSS
    end
  end

  def browser_upgrade_css
    style_(type: 'text/css') do
      <<~CSS.html_safe
        .browser_upgrade {
          position: fixed;
          width: 100%;
          z-index: 9999;
          margin: 0.2em auto;
          padding: 0.2em 0;
          text-align: center;
          background: #ccc;
          color: #000;
          opacity: 0.8;
        }
      CSS
    end
  end

  def browser_upgrade_html
    "<!--[if lt IE 11]><p class='browser_upgrade'>#{t('template.browser_upgrade_html')}</p><![endif]-->".html_safe
  end

  def js_i18n(*scopes)
    (@@js_i18n ||= {})["#{Current.locale}_#{scopes.join('_')}"] ||= scopes.each_with_object({}) do |scope, all|
      all.merge! I18n.t('js', scope: scope, default: {})
    end
  end

  def render_pjax
    render template: "#{@virtual_path}/pjax"
  end

  def back_to_site_link(target_blank = false)
    site_path = try(:pages_root_path) || app_root_path
    if target_blank
      a_(href: site_path, target: '_blank') {[
        t('template.back_to_site'),
        i_('.fa.fa-external-link.sidebar_external')
      ]}
    else
      a_(href: site_path) {[
        i_('.fa.fa-reply'),
        t('template.back_to_site'),
      ]}
    end
  end

  def locale_select
    session_select :locale, I18n.available_locales
  end

  def session_select(name, available_values)
    if name.is_a? Array
      current_label = name.first
      name = name.last
    else
      current_label = Current[name]
    end
    current_value = Current[name]
    case available_values.size
    when 1
      ''
    when 2
      if available_values.first.is_a? Enumerable
        other_label, other_value = available_values.find{ |_label, value| current_value != value.to_s }
      else
        other_value = available_values.find{ |value| current_value != value.to_s }
        other_label = other_value
      end
      if name == :locale
        a_(".#{name}_select.session_select", href: "?_#{name}=#{other_value}", title: I18n.t('template.language')) {[
          i_('.fa.fa-flag'),
          span_(other_label.to_s.humanize)
        ]}
      else
        a_ ".#{name}_select.session_select", other_label.to_s.humanize, href: "?_#{name}=#{other_value}"
      end
    else
      other_values = [[current_label.to_s.humanize, ""]]
      if available_values.first.is_a? Enumerable
        other_values += available_values.reject{ |_label, value| current_value == value.to_s }.map do |label, value|
          [label.to_s.humanize, "?_#{name}=#{value}"]
        end
      else
        other_values += available_values.reject{ |value| current_value == value.to_s }.map do |value|
          [value.to_s.humanize, "?_#{name}=#{value}"]
        end
      end
      div_ ".#{name}_select.session_select" do
        select_tag name.to_s.pluralize, options_for_select(other_values), onchange: "if(this.value){location = this.value}"
      end
    end
  end
end
