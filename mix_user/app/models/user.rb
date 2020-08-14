class User < MixUser.config.parent_model.constantize
  has_userstamp

  devise *MixUser.config.devise_modules

  scope :visible_roles, -> (user) { where(column(:role) <= roles[user.role]) }

  # TODO validate  :role_allowed, if: :role_changed?
  enum role: MixUser.config.available_roles

  json_attribute MixUser.config.json_attributes

  alias_attribute :user_id, :id

  before_validation :set_login

  after_discard :scramble_email_and_password

  validates :role, presence: true

  def self.admin_created?
    admin.exists?
  end

  def admin?
    role_i >= self.class.roles[:admin]
  end

  def user?
    role_i >= self.class.roles[:user]
  end

  def visible_roles_i18n
    visible_roles.map{ |role, i| [self.class.human_attribute_name("role.#{role}"), i] }.to_h
  end

  def visible_roles
    self.class.roles.select{ |_, i| i <= role_i }.except!(:null)
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

  def role_i18n
    self.class.human_attribute_name("role.#{role}")
  end

  def role_i
    read_attribute_before_type_cast(:role)
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
end
