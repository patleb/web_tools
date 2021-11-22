class User < MixUser.config.parent_model.constantize
  has_userstamp

  devise *MixUser.config.devise_modules

  scope :visible_roles, -> (user) { where(column(:role) <= roles[user.as_role]) }

  json_attribute MixUser.config.json_attributes

  alias_attribute :user_id, :id

  enum role: MixUser.config.available_roles

  before_validation :set_login, if: :email_changed?

  after_discard :scramble_email_and_password

  validates :role, presence: true, exclusion: { in: ['null'] }
  validate  :check_deployer, if: :deployer?

  def self.enum_roles
    Current.user.visible_roles
  end

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

  def visible_roles
    self.class.roles.select{ |_, i| i <= as_role_i }.except!(:null)
  end

  def visible_role?(user)
    user.role_i <= as_role_i
  end

  def has?(record)
    record.try(:user_id) == id
  end

  def active_for_authentication?
    super && !discarded?
  end

  def confirmed?
    !!confirmed_at
  end

  def role_i
    self.class.roles[role]
  end

  def as_role_i
    self.class.roles[as_role]
  end

  def as_role
    if Current.as_admin? && role_i >= self.class.roles[:deployer]
      'admin'
    elsif Current.as_user? && role_i >= self.class.roles[:admin]
      'user'
    else
      role
    end
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
    return true unless MixUser.config.scramble_on_discard

    self.email = SecureRandom.uuid + "@example.net"
    self.login = email
    self.password = SecureRandom.hex(8)
    self.password_confirmation = password
    save
  end

  def check_deployer
    unless Setting[:authorized_keys].any?{ |key| key.split(' ').last == email }
      errors.add :role, :deployer_denied
    end
  end
end
