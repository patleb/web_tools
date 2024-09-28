module ActiveModel::Name::WithAdmin
  extend ActiveSupport::Concern

  prepended do
    attr_reader :admin_param
  end

  def initialize(...)
    super
    @admin_param = @name.to_admin_param
  end
end

ActiveModel::Name.prepend ActiveModel::Name::WithAdmin
