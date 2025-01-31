class Flash < LibMainRecord
  class MustBeLoggedIn < ::StandardError; end

  SEPARATOR = '<br>'

  belongs_to :user
  belongs_to :user_session, foreign_key: [:user_id, :session_id]

  validates :session_id, format: { with: Rack::Utils::SESSION_ID }
  validates :messages, presence: true

  after_save :flash_later!

  def self.[](type)
    current.messages[type]
  end

  def self.[]=(type, message)
    current.messages[type] = message
  end

  def self.current
    raise MustBeLoggedIn unless Current.logged_in?
    Current.flash ||= new(user: Current.user, session_id: Current.session_id, messages: {})
  end

  def self.messages(hash = {})
    dequeue_all.each_with_object(hash) do |record, messages|
      record.messages.each do |type, message|
        text = (messages[type.to_sym] ||= +'')
        text << SEPARATOR unless text.blank?
        text << message
      end
    end
  end
  class << self
    alias_method :dequeue_in, :messages
  end

  def self.cleanup
    where(column(:updated_at) < MixFlash.config.flash_expires_in.ago).delete_all
  end

  def self.dequeue_all
    return [] unless Current.logged_in?
    super(:user_id, :session_id, :updated_at) do |user_id, session_id, updated_at|
      <<-SQL
        WHERE #{user_id} = #{Current.user.id}
          AND #{session_id} = '#{Current.session_id}'
        ORDER BY #{updated_at}
      SQL
    end
  end

  private

  def flash_later!
    Current.user_session.flash_later!
  end
end
