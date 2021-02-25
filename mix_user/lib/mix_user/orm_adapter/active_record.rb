require 'orm_adapter/adapters/active_record'

OrmAdapter::ActiveRecord.class_eval do
  def get(id)
    Current.user = get_unscoped.where(id: id).take
  end

  def find_first(options = {})
    construct_relation(klass.unscoped, options).take
  end

  def get_unscoped
    klass.unscoped
  end

  ActiveSupport.run_load_hooks(:orm_adapter_active_record, self)
end
