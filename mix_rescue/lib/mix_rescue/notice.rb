require 'action_view/helpers/text_helper'
require 'mix_setting'

class Notice
  BODY_START = '[NOTIFICATION]'.freeze
  BODY_END = '[END]'.freeze

  include ActionView::Helpers::TextHelper

  def self.deliver!(exception, **options)
    new.deliver!(exception, **options)
  end

  # TODO keep messages in a folder and deliver later when the service becomes available
  def deliver!(exception, subject: nil, before_body: nil, after_body: nil, logger: false)
    subject = [subject, "[#{exception.respond_to?(:name) ? exception.name : exception.class.name}]"].compact.join(' ')
    message = <<~TEXT
      [#{Time.current.utc}]#{BODY_START}
      #{"#{before_body}\n" if before_body}#{exception.backtrace_log}#{"\n#{after_body}" if after_body}
      #{BODY_END}
    TEXT

    require 'mail'
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
            <p>#{context.simple_format(message, {}, sanitize: true)}</p>
          </body>
        </html>
      HTML
    end

    new_error =
      if exception.class.respond_to? :rescue_class
        exception.class.rescue_class.enqueue exception, message
      else
        Rescue.enqueue exception, message
      end

    if new_error
      if logger
        Rails.logger.error message
      else
        puts message
      end

      if Rails.env.test?
        Mail::TestMailer.new({}).deliver! mail
      else
        mail.deliver! unless MixRescue.config.skip_notice
      end
    end
  rescue Errno::ECONNREFUSED => e
    message << <<~TEXT
      #{e.backtrace_log}
    TEXT
  ensure
    if block_given?
      yield message
    end
    return message
  end
end
