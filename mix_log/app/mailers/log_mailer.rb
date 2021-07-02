class LogMailer < MainMailer
  def report(since = nil)
    @report = LogMessage.report(since)
    mail to: Setting[:mail_to]
  end
end
