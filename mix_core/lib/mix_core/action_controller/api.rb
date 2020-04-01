require_rel 'api'

ActionController::API.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
  include self::WithRescue
end
