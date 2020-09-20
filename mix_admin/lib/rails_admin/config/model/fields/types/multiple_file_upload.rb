class RailsAdmin::Config::Model::Fields::MultipleFileUpload < RailsAdmin::Config::Fields::Base
  class AbstractAttachment
    include RailsAdmin::Config::Proxyable
    include RailsAdmin::Config::Configurable

    attr_reader :value

    def initialize(value)
      @value = value
    end

    register_instance_option :thumb_method do
      nil
    end

    register_instance_option :delete_key do
      nil
    end

    register_instance_option :pretty_value do
      if value.present?
        url = resource_url
        if image
          thumb_url = resource_url(thumb_method)
          image_html = image_tag(thumb_url, class: 'img-thumbnail')
          url != thumb_url ? link_to(image_html, url, target: '_blank') : image_html
        else
          link_to(value, url, target: '_blank')
        end
      end
    end

    register_instance_option :image? do
      (url = resource_url.to_s) && url.split('.').last.match?(/jpg|jpeg|png|gif|svg/i)
    end

    def resource_url(_thumb = false)
      raise('not implemented')
    end
  end

  def initialize(*args)
    super
    @attachment_configurations = []
  end

  register_instance_option :render do
    div_({ class: 'input-group' }, [
      attachments.map.with_index do |attachment, i|
        div_('.toggle', [
          attachment.pretty_value_or_blank,
          if delete_method
            a_('.btn.btn-info', { class: 'js_file_remove', href: '#', role: 'button', data: { toggle: 'button' } }, [
              i_('.icon-white.icon-trash'),
              "#{I18n.t('admin.actions.delete.menu').capitalize} #{label.downcase} ##{i + 1}"
            ])
          end,
          form.check_box(delete_method, { multiple: true, class: 'soft_hidden' }, attachment.delete_key, nil)
        ])
      end,
      form.file_field(name, html_attributes.reverse_merge(
        class: 'js_field_input', data: { element: 'file_multi' }, multiple: true)
      ),
      if cache_method
        form.hidden_field(cache_method)
      end
    ])
  end

  register_instance_option :attachment_class do
    AbstractAttachment
  end

  register_instance_option :cache_method do
    nil
  end

  register_instance_option :delete_method do
    nil
  end

  register_instance_option :export_value do
    attachments.map(&:resource_url).map(&:to_s).join(',')
  end

  register_instance_option :pretty_value do
    safe_join attachments.map(&:pretty_value), ' '
  end

  register_instance_option :allowed_methods do
    [method_name, cache_method, delete_method].compact
  end

  register_instance_option :html_attributes do
    { required: required? && !value.present? }
  end

  def attachment(&block)
    @attachment_configurations << block
  end

  def attachments
    Array(value).map do |attached|
      attachment = attachment_class.new(attached)
      @attachment_configurations.each do |config|
        attachment.instance_eval(&config)
      end
      attachment.with(bindings)
    end
  end

  # virtual class
  def virtual?
    true
  end
end
