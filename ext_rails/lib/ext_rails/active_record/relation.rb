require_dir __FILE__, 'relation'

ActiveRecord::Relation.class_eval do
  prepend self::WithAtomicOperations
  include self::WithCalculate
  prepend self::WithJsonAttribute
  prepend self::WithPartition
  prepend self::WithReturningColumn

  def select_without(*fields)
    select(*(column_names - fields.map(&:to_s)))
  end

  def order_group(*columns, reverse: false)
    aliases = columns.map{ |field| column_alias_for(field.to_s.dup).downcase }
    relation = reverse ? order(aliases.index_with(:desc)) : order(*aliases)
    relation.group(*columns)
  end

  alias_method :invert_where_without_scope, :invert_where
  def invert_where(scope = nil)
    return invert_where_without_scope unless scope
    where(scope.arel.constraints.reduce(:and).not)
  end
end

ActiveRecord::Base.class_eval do
  class << self
    delegate :select_without, :order_group, to: :all
    delegate *ActiveRecord::Relation::WithCalculate::QUERYING_METHODS, to: :all
    delegate *ActiveRecord::Relation::WithJsonAttribute::QUERYING_METHODS, to: :all
  end
end
