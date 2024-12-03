module PageFields
  class Link < PageField
    delegate :title, :to_url, to: :fieldable

    with_options unless: :list_changed? do
      validates :fieldable, presence: true
      validates :fieldable_type, inclusion: { in: MixPage.config.available_fieldables }
    end

    def field_label_values
      super << title
    end
  end
end
