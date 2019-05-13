require 'action_view/helpers/text_helper'
require 'mr_secret'

class Notice
  include ActionView::Helpers::TextHelper

  BODY_START = '[NOTIFICATION]'.freeze
  BODY_END = '[END]'.freeze

  # TODO add throttler
  def deliver!(exception, subject:, before_body: nil, after_body: nil)
    require "mail"

    mail = ::Mail.new
    mail.delivery_method :smtp, {
      address: Secret[:mail_address],
      port: Secret[:mail_port],
      domain: Secret[:mail_domain],
      user_name: Secret[:mail_user_name],
      password: Secret[:mail_password],
      authentication: "plain",
      enable_starttls_auto: true,
    }
    mail.to   = Secret[:mail_to]
    mail.from = Secret[:mail_from]
    message = <<~TEXT
      [#{Time.current.utc}]#{BODY_START}
      #{"#{before_body}\n" if before_body}#{exception.backtrace_log}#{"\n#{after_body}" if after_body}
      #{BODY_END}
    TEXT
    mail.subject   = subject.to_s
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
    if defined?(Rails) && Rails.env.test?
      Mail::TestMailer.new({}).deliver! mail
    else
      mail.deliver! unless MrNotifier.config.skip_notice
    end
    message
  rescue Errno::ECONNREFUSED => e
    # TODO keep messages in a folder and deliver later when the service becomes available
    message << <<~TEXT
      #{e.backtrace_log}
    TEXT
  ensure
    yield message if block_given?
  end
end
