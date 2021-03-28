class Flash < LibMainRecord
  class MustBeLoggedIn < ::StandardError; end

  belongs_to :user

  validates :session_id, format: { with: Rack::Utils::SESSION_ID }
  validates :messages, presence: true

  def self.[](type)
    flash.messages[type]
  end

  def self.[]=(type, message)
    flash.messages[type] = message
  end

  def self.cleanup
    where(column(:updated_at) < MixFlash.config.flash_expires_in.ago).delete_all
  end

  def self.dequeue_all
    return [] unless Current.logged_in?
    super(:user_id, :session_id, :updated_at) do |user_id, session_id, updated_at|
      <<-SQL
        WHERE #{user_id} = #{Current.user.id}
          AND #{session_id} = '#{Rails.env.test? ? $test.session_id : Current.session_id}'
        ORDER BY #{updated_at}
      SQL
    end
  end

  def self.flash
    raise MustBeLoggedIn unless Current.logged_in?

    Current.flash ||= new(user: Current.user, session_id: Current.session_id, messages: {})
  end
end
