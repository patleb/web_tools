class User::Null < ActiveType::NullObject
  enum role: MixUser.config.available_roles, default: :null

  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end
  attribute :discarded, :boolean, default: proc{ false }

  alias_attribute :user_id, :id

  def has?(_record)
    false
  end
end
