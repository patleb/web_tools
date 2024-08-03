require 'action_view/helpers/text_helper'
require 'mix_setting'

class Notice
  BODY_START = '[NOTIFICATION]'.freeze
  BODY_END   = '[END]'.freeze

  include ActionView::Helpers::TextHelper

  def self.deliver!(exception, **options)
    require 'mail'
    new.deliver!(exception, **options)
  end

  def deliver!(exception, subject: nil, data: nil)
    unless exception.is_a? RescueError
      exception = RescueError.new(exception, data: data)
    end
    log_message = Log.rescue_not_reportable(exception)
    return if log_message.line_at > MixRescue.config.notice_interval.ago

    subject = [subject, "[#{exception.name}]"].compact.join(' ')
    message = <<~TEXT
      [#{Time.current.utc}][#{Process.host.private_ip}]#{BODY_START}
      #{exception.backtrace_log}
      #{BODY_END}
    TEXT
    mail = ::Mail.new
    mail.delivery_method :smtp, Setting.smtp
    mail.to   = Setting[:mail_to]
    mail.from = Setting[:mail_from]
    mail.subject   = subject
    mail.text_part = ::Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      body message.gsub(/\n/, "\r\n")
    end
    context = self
    mail.html_part = ::Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
          </head>
          <body>
            <code style="white-space: pre;">#{context.sanitize(message).gsub(/\r?\n/, '<br>').gsub(' ', '&nbsp;')}</code>
          </body>
        </html>
      HTML
    end
    if Rails.env.test?
      Mail::TestMailer.new({}).deliver! mail
    else
      mail.deliver! unless MixRescue.config.skip_notice
    end
    log_message.update_attribute :line_at, log_message.new_line_at
  rescue Exception => e
    Log.rescue(e)
  end
end
