class RailsAdmin::Config::Model::Fields::MultipleActiveStorage < RailsAdmin::Config::Model::Fields::MultipleFileUpload
  class ActiveStorageAttachment < RailsAdmin::Config::Model::Fields::MultipleFileUpload::AbstractAttachment
    register_instance_option :thumb_method do
      { resize: '100x100>' }
    end

    register_instance_option :delete_key do
      value.id
    end

    register_instance_option :image? do
      if value
        value.filename.to_s.split('.').last =~ /jpg|jpeg|png|gif|svg/i
      end
    end

    def resource_url(thumb = false)
      return nil unless value
      if thumb && value.variable?
        variant = value.variant(thumb_method)
        Rails.application.routes.url_helpers.rails_blob_representation_path(
          variant.blob.signed_id, variant.variation.key, variant.blob.filename, only_path: true
        )
      else
        Rails.application.routes.url_helpers.rails_blob_path(value, only_path: true)
      end
    end
  end

  register_instance_option :attachment_class do
    ActiveStorageAttachment
  end

  register_instance_option :delete_method do
    "remove_#{name}" if object.respond_to? "remove_#{name}"
  end
end
