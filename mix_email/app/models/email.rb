class Email < LibRecord
  def self.find_by_header!(message)
    order(created_at: :desc).find_by! mailer: message.delivery_handler.name, sent: false, **header(message)
  end

  def self.create_from_header!(message)
    create! mailer: message.delivery_handler.name, **header(message)
  end

  def self.header(message)
    fields = message.header.fields.map{ |f| [f.name.underscore, f.field.to_s] }.to_h
    fields.slice('from', 'to', 'cc', 'bcc', 'subject').reject{ |_,v| v.blank? }.with_keyword_access
  end
end
