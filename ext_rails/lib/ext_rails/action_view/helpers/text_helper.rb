module ActionView
  module Helpers
    module TextHelper
      def simple_format!(text, html_options = {}, options = {})
        options[:sanitize] = false unless options.has_key? :sanitize
        simple_format(text, html_options, options)
      end
    end
  end
end
