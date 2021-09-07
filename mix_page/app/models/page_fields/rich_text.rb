module PageFields
  class RichText < Text
    json_translate title: :string

    has_many_attached :images

    before_validation :create_or_purge_images, on: :update

    with_options on: :update, unless: :list_changed? do
      I18n.available_locales.each do |locale|
        validates "title_#{locale}", length: { maximum: 120 }
      end
    end

    I18n.available_locales.each do |locale|
      before_validation do
        if send("text_#{locale}_changed?") && send("text_#{locale}")&.html_blank?
          send("text_#{locale}=", '')
        end
      end
    end

    def rails_admin_object_label_values
      super << title
    end

    private

    def create_or_purge_images
      urls = images_attachments.map{ |record| [record.url, record] }.to_h
      blobs, texts = {}, {}
      records = I18n.available_locales.each_with_object({}) do |locale, records|
        text = send("text_#{locale}")
        next if text.html_blank?
        body = texts[locale] = Nokogiri::HTML(text).css('body > *')
        body.css('img').each do |img|
          src, filename = img.attributes.values_at('src', 'data-file-name').map(&:to_s)
          if urls.has_key? src
            attachment = urls[src]
            records[attachment.id] ||= attachment
            next
          elsif !src.match? %r{^data:\w+/[-.\w]+;base64,}
            next
          end
          io = StringIO.new(Base64.decode64(src.split(',').last))
          blob = ActiveStorage::Blob.build_after_unfurling(io: io, filename: '') # extract content type by io only
          blob.filename = filename
          (blobs[locale] ||= []) << [img, io, blob]
        end
      end

      error = false
      blobs.each do |locale, list|
        list.each do |(img, io, blob)|
          unless blob.image?
            errors.add("text_#{locale}", :content_type_invalid)
            next (error = true)
          end
          unless blob.byte_size < MixPage.config.max_image_size
            errors.add("text_#{locale}", :file_size_out_of_range, file_size: blob.byte_size)
            next (error = true)
          end
          next if error

          blob = existing_blob(blob) || blob
          if blob.new_record? || blob.backup_missing?
            blob.save!
            blob.backup_file(io)
            blob.upload_without_unfurling(io)
          end
          attachment = images_attachments.find_or_create_by! blob: blob
          records[attachment.id] ||= attachment
          img['src'] = records[attachment.id].url
        end
      end
      return if error

      texts.each do |locale, body|
        send("text_#{locale}=", body.to_html) if blobs[locale].present?
      end

      if records.empty?
        images_attachments.each(&:purge_later)
      else
        images_attachments.where.not(id: records.keys).each(&:purge_later)
      end
    end

    def existing_blob(blob)
      images_blobs.find_by(blob.slice(*%i(filename content_type service_name byte_size checksum)).transform_values(&:to_s))
    end
  end
end
