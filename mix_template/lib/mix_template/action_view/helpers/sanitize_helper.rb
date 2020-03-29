module ActionView
  module Helpers
    module SanitizeHelper
      def strip_tags(html)
        Nokogiri::HTML(html).text
      end
    end
  end
end
