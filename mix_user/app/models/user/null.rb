class User::Null < ActiveType::NullObject
  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end
  attribute :discarded, :boolean, default: proc{ false }
  attribute :role, default: proc{ 'null' }

  alias_attribute :user_id, :id
  attr_writer :role_user

  enum role: MixUser.config.available_roles

  def role_user
    false
  end
  alias_method :role_user?, :role_user

  def has?(_record)
    false
  end
end
