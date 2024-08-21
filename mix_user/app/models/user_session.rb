class UserSession < LibMainRecord
  scope :current, -> { Current.session_id ? where(cookie_id: Current.session_id) : none }
  scope :other, -> { Current.session_id ? where.not(cookie_id: Current.session_id) : none }

  belongs_to :user
end
