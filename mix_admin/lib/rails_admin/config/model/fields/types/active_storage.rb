class RailsAdmin::Config::Model::Fields::ActiveStorage < RailsAdmin::Config::Model::Fields::FileUpload
  register_instance_option :thumb_method do
    { resize: '120x120>' }
  end

  register_instance_option :delete_method do
    "remove_#{name}" if object.respond_to? "remove_#{name}"
  end

  register_instance_option :image? do
    if value
      value.filename.to_s.split('.').last.match? /jpg|jpeg|png|gif|svg/i
    end
  end

  def resource_url(thumb = false)
    return nil unless value
    if thumb && value.variable?
      variant = value.variant(thumb)
      Rails.application.routes.url_helpers.rails_blob_representation_path(
        variant.blob.signed_id, variant.variation.key, variant.blob.filename, only_path: true
      )
    else
      Rails.application.routes.url_helpers.rails_blob_path(value, only_path: true)
    end
  end

  # TODO N+1 "with_attached_#{name}"
  # https://github.com/rails/rails/tree/master/activestorage
  def value
    attachment = super
    attachment if attachment&.attached?
  end
end
