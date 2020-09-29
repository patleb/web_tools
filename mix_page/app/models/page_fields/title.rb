module PageFields
  class Title < Text
    with_options on: :update, unless: :list_changed? do
      I18n.available_locales.each do |locale|
        validates "text_#{locale}", length: { maximum: 120 }
      end
    end
  end
end
