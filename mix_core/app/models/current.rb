class Current < ActiveSupport::CurrentAttributes
  attribute :controller
  attribute :session_id, :request_id, :referer
  attribute :locale, :time_zone, :currency
  attribute :view
  attribute :error_logged
  attribute :virtual_types
end
