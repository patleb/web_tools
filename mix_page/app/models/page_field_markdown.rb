class PageFieldMarkdown < LibMainRecord
  include Admin::WithMarkdown

  belongs_to :page_field, autosave: true

  private

  def convert_to_html_record
    page_field
  end
end
