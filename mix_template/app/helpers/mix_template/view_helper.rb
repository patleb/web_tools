module MixTemplate
  module ViewHelper
    def body_id
      [current_layout, 'layout'].compact.join('_').full_underscore.sub('_pjax_', '_')
    end

    def current_layout(name = nil)
      @_current_layout ||= begin
        layout_controller = self.is_a?(ActionController::Base) ? self : controller
        layout_path = layout_controller.send(:_layout, @lookup_context, [:html])
        layout_path = (layout_path.is_a?(String) ? layout_path : layout_path&.virtual_path) || 'layouts/application'
        layout_path.delete_prefix('layouts/')
      end
      name ? @_current_layout.sub(%r{(^|/)application$}, "\\1#{name}") : @_current_layout
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
      "<!--[if lt IE 11]><p class='browser_upgrade'>#{t('mix_template.browser_upgrade_html')}</p><![endif]-->".html_safe
    end

    def js_i18n(key = 'application.js')
      (@_js_i18n ||= {})["#{Current.locale}_#{key}"] ||= I18n.t(key)
    end

    def render_pjax(path = nil)
      render template: path || "#{@virtual_path}/pjax"
    end

    def back_to_site_link(target_blank = true)
      return unless back_to_site_path.present?
      if target_blank
        a_ [t('mix_template.back_to_site'), i_('.fa.fa-external-link.sidebar_external')], href: back_to_site_path, target: '_blank'
      else
        link_to t('mix_template.back_to_site'), back_to_site_path
      end
    end

    def back_to_site_path
      return @_back_to_site_path if defined? @_back_to_site_path
      @_back_to_site_path = main_app.try(:root_path) || '/'
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
        a_ ".#{name}_select.session_select", other_label.to_s.humanize, href: "?_#{name}=#{other_value}"
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
end
