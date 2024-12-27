class PageLayout < Page
  has_many :page_templates, discardable: :all, dependent: :restrict_with_error

  enum! :view, MixPage.config.available_layouts

  validates :view, uniqueness: true, if: :view_changed?

  def template
    "layouts/#{view}"
  end
end
