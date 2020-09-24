class User::Null < ActiveType::NullObject
  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end
  attribute :discarded, :boolean, default: proc{ false }
  attribute :role, default: proc{ 'null' }

  alias_attribute :user_id, :id
  attr_accessor :role_user
  alias_method :role_user?, :role_user

  enum role: MixUser.config.available_roles

  def has?(_record)
    false
  end
end
