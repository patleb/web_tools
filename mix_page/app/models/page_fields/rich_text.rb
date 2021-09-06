module PageFields
  class RichText < Text
    json_translate title: :string

    has_many_attached :images

    validates :images, attached: true, content_type: [:png, :jpg], on: :update

    before_update :create_or_purge_images

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

    # TODO cron job to clear orphans --> could happen if there is an exception (test + rollback)
    def create_or_purge_images
      urls = images_attachments.map{ |record| [record.url, record] }.to_h
      attachments = I18n.available_locales.each_with_object({}) do |locale, memo|
        text = send("text_#{locale}")
        next if text.html_blank?
        body = Nokogiri::HTML(text).css('body > *')
        update = false
        body.css('img').each do |img|
          src, filename = img.attributes.values_at('src', 'data-file-name').map(&:to_s)
          if urls.has_key? src
            attachment = urls[src]
            memo[attachment.id] ||= attachment
            next
          elsif !src.match? %r{^data:\w+/[-.\w]+;base64,}
            next
          end
          update = true
          io = StringIO.new(Base64.decode64(src.split(',').last))
          blob = ActiveStorage::Blob.build_after_unfurling(io: io, filename: filename)
          blob = existing_blob(blob) || blob
          if blob.new_record?
            blob.save!
            blob.upload_without_unfurling(io)
          end
          attachment = images_attachments.find_or_create_by! blob: blob
          memo[attachment.id] ||= attachment
          img['src'] = memo[attachment.id].url
        end
        send("text_#{locale}=", body.to_html) if update
      end
      if attachments.empty?
        images_attachments.each(&:purge_later)
      else
        images_attachments.where.not(id: attachments.keys).each(&:purge_later)
      end
    end

    def existing_blob(blob)
      images_blobs.find_by(blob.slice(*%i(filename content_type service_name byte_size checksum)).transform_values(&:to_s))
    end
  end
end
