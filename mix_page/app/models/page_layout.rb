class PageLayout < Page
  has_many :page_templates, -> { with_discarded }, dependent: :restrict_with_error

  enum view: MixPage.config.available_layouts

  validates :view, uniqueness: true, if: :view_changed?
end
