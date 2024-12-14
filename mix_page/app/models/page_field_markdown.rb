class PageFieldMarkdown < LibMainRecord
  BLOB_ID = /!\[[^\]]+\]\(blob:(\d+)\)/

  belongs_to :page_field

  json_translate text: :string

  after_update :convert_to_html

  def self.renderer
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

  private

  def convert_to_html
    I18n.available_locales.each do |locale|
      attribute = "text_#{locale}"
      text = self[attribute] || ''
      text = convert_blobs_to_urls(text)
      page_field[attribute] = self.class.renderer.render(text)
    end
    page_field.save!
  end

  def convert_blobs_to_urls(text)
    text.gsub(BLOB_ID) do |match|
      blob = ActiveStorage::Blob.find($1)
      match.sub(/blob:(\d+)/, blob.url)
    end
  end
end
