ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun

  private

  def i18n_subject(interpolations = {})
    mailer_scope = self.class.mailer_name.tr("/", ".")
    I18n.t(:subject, **interpolations.merge(scope: [mailer_scope, action_name]))
  end
end
