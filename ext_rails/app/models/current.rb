class Current < ActiveSupport::CurrentAttributes
  attribute :controller, :controller_was
  attribute :session_id, :request_id
  attribute :locale,   default: I18n.default_locale
  attribute :timezone, default: Rails.application.config.time_zone
  attribute :theme,    default: ExtRails.config.theme
  attribute :view
  attribute :virtual_records
  attribute :discarded, :discardable

  def self.with(**values)
    old_values = attributes.slice(*values.keys)
    yield attributes.merge!(values)
  ensure
    values.each_key do |name|
      attributes[name] = old_values[name]
    end
  end

  alias_method :discarded?, :discarded

  def undiscarded
    !discarded
  end
  alias_method :undiscarded?, :undiscarded

  alias_method :discardable_without_default, :discardable
  def discardable
    (value = discardable_without_default).is_a?(Boolean) ? value : true
  end
  alias_method :discardable?, :discardable

  def undiscardable
    !discardable
  end
  alias_method :undiscardable?, :undiscardable
end
