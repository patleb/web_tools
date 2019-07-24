module MrTemplate
  module SanitizeHelper
    def strip_tags(html)
      Nokogiri::HTML(html).text
    end
  end
end
