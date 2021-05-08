class User::Null < ActiveType::NullObject
  enum role: MixUser.config.available_roles, default: :null

  MixUser.config.json_attributes.each do |name, type|
    attribute name, type
  end

  alias_attribute :user_id, :id

  def discarded
    false
  end
  alias_method :discarded?, :discarded

  def has?(_record)
    false
  end
end
