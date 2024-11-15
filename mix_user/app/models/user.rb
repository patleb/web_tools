class User < LibMainRecord
  has_userstamps
  has_secure_password

  generates_token_for :verified, expires_in: MixUser.config.verification_expires_in do
    email
  end

  generates_token_for :password, expires_in: MixUser.config.reset_expires_in do
    password_salt.last(10)
  end

  generates_token_for :deleted, expires_in: MixUser.config.restore_expires_in do
    deleted_at
  end

  scope :unverified,    -> { where(verified_at: nil) }
  scope :verified,      -> { where.not(verified_at: nil) }
  scope :allowed_roles, -> (user) { where(column(:role) <= roles[user.as_role]) }

  has_many :sessions, class_name: 'UserSession', dependent: :destroy
  has_one  :session, -> { current }, class_name: 'UserSession'

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: MixUser.config.min_password_length }
  validates :role, presence: true
  validate  :check_role, if: :role_changed?

  normalizes :email, with: ->(email) { email.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified_at = nil
  end
  after_update :delete_other_sessions, if: -> do
    password_digest_previously_changed? || verified_at_previously_changed? || role_previously_changed?
  end
  after_discard :unverified!

  json_attribute MixUser.config.json_attributes

  alias_method :user_id, :id

  enum role: MixUser.config.available_roles

  def self.admin_created?
    admin.exists?
  end

  roles.each do |name, value|
    define_method "role_#{name}?" do
      role_i >= value
    end

    define_method "#{name}?" do
      as_role_i >= value
    end
  end

  def available_roles
    self.class.roles.select{ |_, i| i <= role_i }.except!(:null)
  end

  def allowed_roles
    self.class.roles.select{ |_, i| i <= as_role_i }.except!(:null)
  end

  def allowed_role?(user)
    user.role_i <= as_role_i
  end

  def has?(record)
    record.try(:user_id) == id
  end

  def create_session!(ip_address:, user_agent:)
    sessions.create! session_id: Current.session_id, ip_address: ip_address, user_agent: user_agent
  end

  def session_id
    session&.sid
  end

  def active?
    verified? && !discarded?
  end

  def inactive?
    !active?
  end

  def verified!
    update! verified_email: email, verified_at: Time.current
  end

  def unverified!
    update! verified_at: nil
  end

  def verified?
    !!verified_at
  end

  def unverified?
    !verified_at
  end

  def delete_other_sessions
    sessions.other.delete_all
  end

  def role_i
    self.class.roles[role]
  end

  def as_role_i
    self.class.roles[as_role]
  end

  def as_role
    if Current.as_admin? && role_i >= self.class.roles[:deployer]
      :admin
    elsif Current.as_basic? && role_i >= self.class.roles[:admin]
      :basic
    else
      role
    end
  end

  private

  def check_role
    unless available_roles.has_key? role
      errors.add :role, :role_denied
    end
    if role_deployer? && Setting[:authorized_keys].none?{ |key| key.split(' ').last == email }
      errors.add :role, :deployer_denied
    end
  end
end
