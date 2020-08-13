class Rescue < LibRecord
  NEW_ERROR = true
  OLD_ERROR = false

  self.postgres_exception_to_error = false

  with_options presence: true do
    validates :exception
    validates :message
  end

  def self.enqueue(exception, message = exception.message)
    id = Digest.md5_hex(sti_name, exception.name, message.squish_numbers)
    create!(
      id: id,
      type: sti_name,
      exception: exception.name,
      message: message,
      data: exception.data,
    )
    NEW_ERROR
  rescue ActiveRecord::RecordNotUnique
    increment_counter(:events_count, id, touch: true)
    OLD_ERROR
  end
end
