class Rescue < LibRecord
  NEW_ERROR = true
  OLD_ERROR = false

  self.postgres_exception_to_error = false

  with_options presence: true do
    validates :type
    validates :exception
    validates :message
  end

  enum type: MixRescue.config.available_types

  def self.enqueue(exception, message = nil, unique: false)
    unless exception.class.respond_to? :rescue_class
      exception = RescueError.new(exception)
    end
    message ||= exception.message
    type = exception.class.rescue_class.to_s
    id = unique ? UUID.create.to_s.remove('-') : Digest.md5_hex(type, exception.name, message.squish_numbers.squish!)
    create! id: id, type: type, exception: exception.name, message: message.lines, data: exception.data
    NEW_ERROR
  rescue ActiveRecord::RecordNotUnique
    increment_counter(:events_count, id, touch: true)
    OLD_ERROR
  end
end
