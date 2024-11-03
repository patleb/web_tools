module FlashContext
  extend ActiveSupport::Concern

  included do
    fixtures :users

    let!(:current_user) do
      Current.user = users(:basic)
    end
    let!(:session_id) do
      create_session!
    end
  end
end
