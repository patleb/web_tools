class User::Null < ActiveType::NullObject
  enum role: MixUser.config.available_roles

  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end
  attribute :discarded, :boolean, default: proc{ false }
  attribute :role, default: proc{ 'null' }

  alias_attribute :user_id, :id

  def has?(_record)
    false
  end

  def role_for_database
    self.class.roles[:null]
  end
end
