ActionController::API.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
end
