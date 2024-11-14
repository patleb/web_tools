# frozen_string_literal: true

module LibHelper
  def current_layout
    layouts.first
  end

  def layouts
    @layouts ||= begin
      layout_controller = is_a?(ActionController::Base) ? self : controller
      layout_path = layout_controller.send(:_layout, @lookup_context || @_lookup_context, [:html])
      [(layout_path.is_a?(String) ? layout_path : layout_path.virtual_path).delete_prefix('layouts/')]
    end
  end

  def body_layout
    layouts.map{ |name| [name, 'layout'].join('_').full_underscore }
  end

  def body_template
    [template_virtual_path, 'template'].compact.join('_').full_underscore
  end

  def flash_message(key, scope: nil)
    return unless (message = flash[key]).present?
    scope = [scope, :flash].compact
    message = case message
      when Hash, Array
        message.map do |(type, messages)|
          raise "unsupported flash type: #{type}" unless type.is_a? Symbol
          method_name = [*scope, type].join('_')
          public_send(method_name, messages)
        end.join("\n")
      when Symbol then t(message, scope: scope)
      when String then message
      else raise "unsupported flash object: #{message.class.name}"
      end
    css_class = case key
      when :alert  then 'alert-error'
      when :notice then 'alert-info'
      else raise "unsupported flash key: #{key}"
      end
    h_(
      input_(id: key, type: 'checkbox'),
      div_('.alert.shadow-xl', class: css_class) {[
        span_(simple_format! message),
        label_('.btn.btn-circle.btn-xs', ascii(:x), for: key),
      ]},
    )
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

  def locale_select
    param_select :locale, Current.locale, I18n.available_locales, 'flag' do |locale|
      t("locale.#{locale}", locale: locale)
    end
  end

  def theme_select
    param_select :theme, Current.theme, ExtRails.config.themes, 'circle-half' do |theme|
      t("theme.#{theme}")
    end
  end

  def param_select(name, value, choices, icon_name)
    case choices.size
    when 0, 1
      nil
    when 2
      other, other_icon = choices.find{ |choice, *| choice != value }
      icon_name = other_icon unless other_icon.nil?
      label = yield(other) || other.to_s.humanize
      li_ title: t("link.#{name}", default: name.to_s.humanize) do
        a_ '.param_select', [icon(icon_name), label], remote: true, visit: true, params: { "_#{name}" => other }
      end
    else
      div_('.param_select.form-control', title: t("link.#{name}", default: name.to_s.humanize)) {[
        label_('.input-group', [
          icon(icon_name, tag: :span),
          select_('.select', name: "_#{name}", remote: true, visit: true) do
            choices.map do |choice, *|
              label = yield(choice) || label.to_s.humanize
              option_ label, value: choice, selected: choice == value
            end
          end
        ])
      ]}
    end
  end
end
