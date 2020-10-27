module PageFields
  class RichText < Text
    json_translate title: :string

    with_options on: :update, unless: :list_changed? do
      I18n.available_locales.each do |locale|
        validates "title_#{locale}", length: { maximum: 120 }
      end
    end

    I18n.available_locales.each do |locale|
      before_validation do
        if send("text_#{locale}_changed?") && send("text_#{locale}")&.html_blank?
          send("text_#{locale}=", '')
        end
      end
    end
  end
end
