# frozen_string_literal: true

module LogLines
  class Email < LogLine
    json_attribute(
      mailer: :string,
      from: :string,
      to: :string,
      cc: :string,
      bcc: :string,
      subject: :string,
      sent: :boolean,
    )

    def self.push(log, message, sent: nil)
      json_data = { mailer: mailer(message), **header(message), sent: sent }
      message = { text: json_data[:subject], level: :info }
      super(log, message: message, json_data: json_data)
    end

    def self.mailer(message)
      message.delivery_handler&.name || 'Notice'
    end

    def self.header(message)
      fields = message.header_fields.map{ |f| [f.name.underscore, f.field.to_s] }.to_h
      fields.slice('from', 'to', 'cc', 'bcc', 'subject').compact_blank.with_indifferent_access
    end
  end
end
