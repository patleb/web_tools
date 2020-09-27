module PageFields
  class RichText < Text
    I18n.available_locales.each do |locale|
      before_validation do
        if send("text_#{locale}_changed?") && send("text_#{locale}")&.html_blank?
          send("text_#{locale}=", '')
        end
      end
    end
  end
end
