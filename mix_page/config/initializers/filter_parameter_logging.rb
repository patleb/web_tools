Rails.application.config.filter_parameters += I18n.available_locales.flat_map{ |l| [:"text_#{l}", :"html_#{l}"] }
