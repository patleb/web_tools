module RailsAdmin::Config::Model::Fields::OdooOne::Formatter
  extend ActiveSupport::Concern

  included do
    def pretty_format_one(value = self.value)
      case value
      when Hash
        value[:text]
      else
        value
      end
    end

    def export_format_one(value = self.value)
      case value
      when Hash
        value[:value]
      else
        value
      end
    end
  end
end
