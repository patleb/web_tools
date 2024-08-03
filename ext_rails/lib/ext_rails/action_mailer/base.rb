ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
end
