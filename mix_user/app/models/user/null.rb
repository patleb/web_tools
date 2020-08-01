class User::Null < ActiveType::NullObject
  attribute :first_name
  attribute :last_name
  attribute :discarded, :boolean, default: proc{ false }
  attribute :role, default: proc{ 'null' }

  alias_attribute :user_id, :id

  enum role: MixUser.config.available_roles

  def has?(_record)
    false
  end

  def can?(action, record)
    # TODO
  end
end
