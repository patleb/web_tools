class User < MixUser.config.parent_model.constantize
  has_userstamp

  devise *MixUser.config.devise_modules

  enum role: MixUser.config.available_roles

  json_attribute MixUser.config.json_attributes.merge(
    first_name: :string,
    last_name: :string,
    login: :string
  )

  alias_attribute :user_id, :id

  before_validation :set_login

  after_discard :scramble_email_and_password

  validates :role, presence: true
  # TODO validate  :role_allowed, if: :role_changed?

  def self.admin_created?
    admin.exists?
  end

  def has?(record)
    record.try(:user_id) == id
  end

  def can?(action, record)
    # TODO
  end

  def active_for_authentication?
    super && !discarded?
  end

  def confirmed?
    !!confirmed_at
  end

  protected

  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end

  private

  def set_login
    # for now force login to be same as email, eventually we will make this configurable, etc.
    self.login ||= email if email
  end

  def scramble_email_and_password
    return true if discarded?

    self.email = SecureRandom.uuid + "@example.net"
    self.login = email
    self.password = SecureRandom.hex(8)
    self.password_confirmation = password
    save
  end
end
