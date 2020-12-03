# TODO Rails 6.1 merged --> https://github.com/rails/rails/issues/2686

module ActionMailer::Base::WithAttachmentFix
  def mail(headers = {}, &block)
    super

    # do nothing if we have no actual attachments
    return if @_message.parts.select { |p| p.attachment? && !p.inline? }.none?

    mail = Mail.new

    related = Mail::Part.new
    related.content_type = @_message.content_type
    @_message.parts.select { |p| !p.attachment? || p.inline? }.each { |p| related.add_part(p) }
    mail.add_part related

    mail.header       = @_message.header.to_s
    mail.bcc          = @_message.header[:bcc].value # copy bcc manually because it is omitted in header.to_s
    mail.content_type = nil
    @_message.parts.select { |p| p.attachment? && !p.inline? }.each { |p| mail.add_part(p) }

    @_message = mail
    wrap_delivery_behavior!(delivery_method.to_sym)
  end
end

ActionMailer::Base.prepend ActionMailer::Base::WithAttachmentFix
