module PageFields
  class Link < Text
    delegate :to_url, to: :fieldable

    json_translate text: [:string, default: ->(record) { record.fieldable&.title }]

    validates :fieldable, presence: true, on: :update
    I18n.available_locales.each do |locale|
      validates "text_#{locale}", length: { maximum: 120 }
    end
  end
end
