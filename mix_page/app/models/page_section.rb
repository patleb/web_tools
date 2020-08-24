class PageSection < LibRecord
  belongs_to :page, counter_cache: true, touch: true
  belongs_to :page_section, optional: true, counter_cache: true
  has_many   :page_sections, dependent: :destroy
  has_many   :page_fields, dependent: :destroy
  # TODO STI conversion
  # https://stackoverflow.com/questions/11118413/rails-sti-association-with-subclasses
end
