class User::Null < ActiveType::NullObject
  enum :role, MixUser.config.available_roles, type: :integer, default: :null
  alias_method :as_role, :role

  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end

  alias_method :user_id, :id

  def discarded
    false
  end
  alias_method :discarded?, :discarded

  roles.each_key do |name|
    alias_method "role_#{name}?", "#{name}?"
  end

  def has?(_record)
    false
  end

  def active?
    false
  end

  def inactive?
    !active?
  end

  def verified?
    true
  end

  def unverified?
    !verified?
  end

  def session
    nil
  end

  def updated_at
    nil
  end
end
