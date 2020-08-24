class PageLayout < Page
  has_many :page_templates, dependent: :restrict_with_error

  enum view: MixPage.config.available_layouts
end
