class LogMailer < MainMailer
  def report
    @report = LogMessage.report
    mail to: Setting[:mail_to]
  end
end
