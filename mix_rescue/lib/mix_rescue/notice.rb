require 'action_view/helpers/text_helper'
require 'mix_setting'

# TODO https://github.com/excid3/noticed
class Notice
  BODY_START = '[NOTIFICATION]'.freeze
  BODY_END = '[END]'.freeze

  include ActionView::Helpers::TextHelper

  def self.deliver!(exception, **options)
    require 'mail'
    new.deliver!(exception, **options)
  end

  def deliver!(exception, subject: nil, data: nil)
    exception = RescueError.new(exception, data: data) unless exception.is_a? RescueError
    subject = [subject, "[#{exception.name}]"].compact.join(' ')
    message = <<~TEXT
      [#{Time.current.utc}]#{BODY_START}
      #{exception.backtrace_log}
      #{BODY_END}
    TEXT

    unless (log_label = Log.rescue(exception)).alerted?
      mail = ::Mail.new
      mail.delivery_method :smtp, {
        address: Setting[:mail_address],
        port: Setting[:mail_port],
        domain: Setting[:mail_domain],
        user_name: Setting[:mail_username],
        password: Setting[:mail_password],
        authentication: "plain",
        enable_starttls_auto: true,
      }
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
              <code style="white-space: pre;">#{context.sanitize(message)}</code>
            </body>
          </html>
        HTML
      end

      if Rails.env.test?
        Mail::TestMailer.new({}).deliver! mail
      else
        mail.deliver! unless MixRescue.config.skip_notice
      end

      log_label.toggle! :alerted
    end
  rescue Errno::ECONNREFUSED => e
    Log.rescue(e)
  end
end
