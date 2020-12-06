class Email < LibRecord
  def self.find_by_header!(message)
    order(created_at: :desc).find_by! mailer: mailer(message), sent: false, **header(message)
  end

  def self.create_from_header!(message)
    create! mailer: mailer(message), **header(message)
  end

  def self.mailer(message)
    message.delivery_handler.name
  end

  def self.header(message)
    fields = message.header_fields.map{ |f| [f.name.underscore, f.field.to_s] }.to_h
    fields.slice('from', 'to', 'cc', 'bcc', 'subject').reject{ |_,v| v.blank? }.with_keyword_access
  end
end
