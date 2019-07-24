require_rel 'api'

ActionController::API.class_eval do
  include ActionController::MimeResponds
  include self::WithRescue
end
