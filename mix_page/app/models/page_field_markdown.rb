class PageFieldMarkdown < LibMainRecord
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
      page_field[attribute] = self.class.renderer.render(self[attribute] || '')
    end
    page_field.save!
  end
end
