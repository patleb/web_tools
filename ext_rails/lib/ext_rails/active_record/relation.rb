require 'ext_rails/active_record/relation/with_atomic_operations'
require 'ext_rails/active_record/relation/with_calculate'
require 'ext_rails/active_record/relation/with_json_attribute'
require 'ext_rails/active_record/relation/with_returning_column'

ActiveRecord::Relation.class_eval do
  prepend self::WithAtomicOperations
  include self::WithCalculate
  prepend self::WithJsonAttribute
  prepend self::WithReturningColumn

  def select_without(*fields)
    select(*(column_names - fields.map(&:to_s)))
  end

  def order_group(*columns, reverse: false)
    aliases = columns.map{ |field| column_alias_for(field.to_s.dup).downcase }
    relation = reverse ? order(aliases.map{ |column| [column, :desc] }.to_h) : order(*aliases)
    relation.group(*columns)
  end
end

ActiveRecord::Base.class_eval do
  class << self
    delegate :select_without, :order_group, to: :all
    delegate *ActiveRecord::Relation::WithCalculate::QUERYING_METHODS, to: :all
    delegate *ActiveRecord::Relation::WithJsonAttribute::QUERYING_METHODS, to: :all
  end
end
