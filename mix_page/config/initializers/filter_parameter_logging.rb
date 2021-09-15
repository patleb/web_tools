Rails.application.config.filter_parameters += I18n.available_locales.map{ |locale| :"text_#{locale}" }
