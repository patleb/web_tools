module PageFields
  class Link < Text
    delegate :to_url, to: :fieldable

    json_translate text: [:string, default: ->(record) { record.fieldable&.title }]

    with_options on: :update do
      validates :fieldable, presence: true
      validates :fieldable_type, inclusion: { in: ['PageTemplate'] }
      I18n.available_locales.each do |locale|
        validates "text_#{locale}", length: { maximum: 120 }
      end
    end
  end
end
