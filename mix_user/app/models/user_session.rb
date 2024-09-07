class UserSession < LibMainRecord
  scope :current, -> { Current.session_id ? where(session_id: Current.session_id) : none }
  scope :other, -> { Current.session_id ? where.not(session_id: Current.session_id) : none }

  belongs_to :user

  alias_attribute :sid, :session_id
end
