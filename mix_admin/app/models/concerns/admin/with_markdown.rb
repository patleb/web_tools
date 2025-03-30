module Admin::WithMarkdown
  extend ActiveSupport::Concern

  BLOB_ID = /\(blob:(\d+)\)/
  BLOB_MD = /!\[[^\]]+\]#{BLOB_ID}/

  included do
    has_many_attached :images, dependent: :detach

    json_translate text: :string

    before_validation :convert_to_html, on: :update
  end

  class_methods do
    def renderer
      @renderer ||= Redcarpet::Markdown.new(
        Redcarpet::Render::HTML.new(filter_html: false),
        autolink: true,
        highlight: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        lax_spacing: true,
        strikethrough: true,
        tables: true
      )
    end
  end

  private

  def convert_to_html_record
    self
  end

  def convert_to_html
    return unless I18n.available_locales.any?{ |locale| send("text_#{locale}_changed?") }
    error = false
    blobs, texts = Set.new, {}
    I18n.available_locales.each do |locale|
      attribute = "text_#{locale}"
      text = self[attribute] || ''
      text = text.gsub(BLOB_MD) do |match|
        blob = ActiveStorage::Blob.find($1)
        unless blob.image?
          errors.add(attribute, :content_type_invalid)
          next (error = true)
        end
        unless blob.byte_size < MixAdmin.config.max_file_size
          errors.add(attribute, :file_size_out_of_range, file_size: blob.byte_size)
          next (error = true)
        end
        next if error
        blobs << blob
        match.sub(BLOB_ID, "(#{blob.url})")
      end
      texts[attribute] = text
    end
    return if error

    text_record = convert_to_html_record
    texts.each do |attribute, text|
      text = self.class.renderer.render(text)
      text = '' if text.html_blank?
      text_record[attribute] = text
    end

    attachments = blobs.map do |blob|
      images_attachments.find_or_create_by!(blob: blob)
    end

    if attachments.empty?
      images_attachments.each(&:destroy!)
    else
      images_attachments.where.not(id: attachments).each(&:destroy!)
    end
  end
end
