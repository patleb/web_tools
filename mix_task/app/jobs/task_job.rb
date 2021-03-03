class TaskJob < ActiveJob::Base
  def perform(name, *arguments)
    task = Task.find(name)
    task.perform(arguments)
    Flash[:alert] = I18n.t('task.flash.success_html', name: task.name, path: task.path)
    email_message = I18n.t('task.email.success', name: task.name, duration: task.duration)
  rescue ActiveRecord::RecordInvalid
    Flash[:error] = I18n.t('task.flash.failure_html', name: task.name, path: task.path) + MixTemplate::ERROR_SEPARATOR
    Flash[:error] += (errors = task.errors.full_messages.join(MixTemplate::ERROR_SEPARATOR)) # should be only one error
    email_message = I18n.t('task.email.failure', name: task.name, errors: errors)
  ensure
    if email_message && task&.notify?
      TaskMailer.with(email: task.updater.email, message: email_message).notify.deliver_later!
    end
  end
end
