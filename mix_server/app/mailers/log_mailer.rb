class LogMailer < LibMailer
  def report
    @report = Log.report
    mail to: Setting[:mail_to]
  end
end
