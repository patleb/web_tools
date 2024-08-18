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
        end
      when Symbol then I18n.t(message, scope: scope)
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
        span_(message),
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
