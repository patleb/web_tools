module RailsAdmin::Config::Model::Fields::Integer::Formatter
  extend ActiveSupport::Concern

  included do
    def format_integer(value = self.value)
      value&.pretty_int&.gsub(' ', '&nbsp;')&.html_safe
    end
  end
end
