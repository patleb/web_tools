module ActiveModel::Name::WithAdmin
  extend ActiveSupport::Concern

  prepended do
    attr_reader :admin_param
    alias_method :admin_param_key, :singular
  end

  def initialize(*)
    super
    @admin_param = @name.to_admin_param
  end
end

ActiveModel::Name.prepend ActiveModel::Name::WithAdmin
