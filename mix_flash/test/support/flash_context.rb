module FlashContext
  extend ActiveSupport::Concern

  included do
    fixtures :users

    let!(:current_user) do
      Current.user = users(:basic)
    end
    let!(:session_id) do
      Current.session_id = user.sessions.create!(
        session_id: SecureRandom.hex(16),
        ip_address: '127.0.0.1',
        user_agent: []
      ).sid
    end
  end
end
