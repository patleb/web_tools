module PageFields
  class Link < Text
    delegate :title, :view, :uuid, :to_url, to: :fieldable, allow_nil: true

    json_translate text: [:string, default: ->(record) { record.title }]

    with_options on: :update, unless: :list_changed? do
      validates :fieldable, presence: true
      validates :fieldable_type, inclusion: { in: ['PageTemplate'] }
      I18n.available_locales.each do |locale|
        validates "text_#{locale}", length: { maximum: 120 }
      end
    end
  end
end
