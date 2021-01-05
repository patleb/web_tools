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

    def self.push(log_id, message, sent: nil)
      insert log_id: log_id, json_data: { mailer: mailer(message), **header(message), sent: sent }
    end

    def self.mailer(message)
      message.delivery_handler.name
    end

    def self.header(message)
      fields = message.header_fields.map{ |f| [f.name.underscore, f.field.to_s] }.to_h
      fields.slice('from', 'to', 'cc', 'bcc', 'subject').reject{ |_,v| v.blank? }.with_keyword_access
    end
  end
end
