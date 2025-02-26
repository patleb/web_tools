class TaskJob < ActiveJob::Base
  discard_on ActiveRecord::RecordNotFound

  def perform(name)
    task = Task.find(name)
    task.perform!
    Flash[:notice] = I18n.t('task.flash.success_html', name: task.name, path: task.path)
    email_message = I18n.t('task.email.success', name: task.name, duration: task.duration)
  rescue ActiveRecord::RecordInvalid
    Flash[:alert] = I18n.t('task.flash.failure_html', name: task.name, path: task.path) + ExtRails::ERROR_SEPARATOR
    Flash[:alert] += (errors = task.errors.full_messages.join(ExtRails::ERROR_SEPARATOR)) # should be only one error
    email_message = I18n.t('task.email.failure', name: task.name, errors: errors)
  ensure
    if email_message && task.notify? && task.updater&.email
      TaskMailer.with(email: task.updater.email, message: email_message).notify.deliver_later
    end
  end
end
