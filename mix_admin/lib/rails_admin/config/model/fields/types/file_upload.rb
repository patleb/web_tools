class RailsAdmin::Config::Model::Fields::FileUpload < RailsAdmin::Config::Model::Fields::Base
  register_instance_option :render do
    can_edit = value
    will_destroy = can_edit && delete_method && form.object.send(delete_method).to_b
    can_destroy = optional? && errors.blank? && can_edit && delete_method
    div_('.js_file_wrapper.input-group', [
      div_('.js_file_toggle', class: ('soft_hidden' if will_destroy)) do
        pretty_value
      end,
      div_('.js_file_toggle', { class: ('soft_hidden' if will_destroy) }, [
        form.label(name, class: 'btn btn-default btn-block') do
          # TODO add cancel button and change new for edit if already present
          h_(
            div_({ class: ('soft_hidden' if can_edit) }, [
              i_('.fa.fa-plus'),
              t('admin.actions.new.menu'),
            ]),
            div_({ class: ('soft_hidden' unless can_edit) }, [
              i_('.fa.fa-pencil'),
              t('admin.actions.edit.menu'),
            ]),
            form.file_field(name, html_attributes.reverse_merge(class: 'hidden js_field_input js_file'))
          )
        end
      ]),
      h_if(can_destroy) do[
        a_('.btn.btn-block', { class: ['js_file_remove', will_destroy ? 'btn-danger' : 'btn-info'], href: '#', 'data-toggle': 'button', role: 'button' }, [
          i_('.fa.fa-trash-o.icon-white'),
          t('admin.actions.delete.menu')
        ]),
        form.check_box(delete_method, class: 'hidden')
      ]end,
      if cache_method
        form.hidden_field(cache_method)
      end
    ])
  end

  register_instance_option :thumb_method do
    nil
  end

  register_instance_option :delete_method do
    nil
  end

  register_instance_option :cache_method do
    nil
  end

  register_instance_option :export_value do
    resource_url.to_s
  end

  register_instance_option :pretty_value do
    next unless value.presence
    url = resource_url
    if image
      thumb_url = resource_url(thumb_method)
      image_html = image_tag(thumb_url, class: 'js_file_thumbnail img-thumbnail')
      url != thumb_url ? link_to(image_html, url, target: '_blank') : image_html
    else
      link_to(value, url, target: '_blank')
    end
  end

  register_instance_option :image? do
    (url = resource_url.to_s) && url.split('.').last =~ /jpg|jpeg|png|gif|svg/i
  end

  register_instance_option :allowed_methods do
    [method_name, delete_method, cache_method].compact
  end

  register_instance_option :html_attributes do
    { required: required? && !value.present? }
  end

  # virtual class
  def resource_url
    raise('not implemented')
  end

  def virtual?
    true
  end
end
