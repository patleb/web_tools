MonkeyPatch.add{['activerecord', 'lib/active_record/associations/preloader/through_association.rb', '02b503f5044bbd555280ca8245b08ded1da118f922d4feab0b2040824f5c1011']}
MonkeyPatch.add{['activerecord', 'lib/active_record/associations/association_scope.rb', '8ab906a330ebb595561718e2130bcb8438f05812b36520b7990e7879939f130b']}
MonkeyPatch.add{['activerecord', 'lib/active_record/associations/has_many_through_association.rb', '0126fc5a7b210668826e03d67784719e408b5052c94035fc0269a09af76c9c37']}
MonkeyPatch.add{['activerecord', 'lib/active_record/reflection.rb', '58159d5e41220734d6054fd1dde8f75ffff7436379e36d60d6dd9fac7f8647ca']}

### References
# https://github.com/appfolio/store_base_sti_class/blob/master/lib/store_base_sti_class.rb
module ActiveRecord
  Base.class_eval do
    class_attribute :store_base_sti_class
    self.store_base_sti_class = true
  end

  module Inheritance
    module ClassMethods
      def polymorphic_name
        ActiveRecord::Base.store_base_sti_class ? base_class.name : name
      end
    end
  end

  module Associations
    Preloader::ThroughAssociation.class_eval do
      private

      def through_scope
        scope = through_reflection.klass.unscoped
        options = reflection.options

        return scope if options[:disable_joins]

        values = reflection_scope.values
        if annotations = values[:annotate]
          scope.annotate!(*annotations)
        end

        if options[:source_type]
          foreign_type = options[:source_type]
          unless ActiveRecord::Base.store_base_sti_class
            foreign_type = ([foreign_type.to_const] + foreign_type.to_const.descendants).map(&:to_s)
          end
          scope.where! reflection.foreign_type => foreign_type
        elsif !reflection_scope.where_clause.empty?
          scope.where_clause = reflection_scope.where_clause

          if includes = values[:includes]
            scope.includes!(source_reflection.name => includes)
          else
            scope.includes!(source_reflection.name)
          end

          if values[:references] && !values[:references].empty?
            scope.references_values |= values[:references]
          else
            scope.references!(source_reflection.table_name)
          end

          if joins = values[:joins]
            scope.joins!(source_reflection.name => joins)
          end

          if left_outer_joins = values[:left_outer_joins]
            scope.left_outer_joins!(source_reflection.name => left_outer_joins)
          end

          if scope.eager_loading? && order_values = values[:order]
            scope = scope.order(order_values)
          end
        end

        cascade_strict_loading(scope)
      end
    end

    AssociationScope.class_eval do
      private

      def next_chain_scope(scope, reflection, next_reflection)
        primary_key = Array(reflection.join_primary_key)
        foreign_key = Array(reflection.join_foreign_key)

        table = reflection.aliased_table
        foreign_table = next_reflection.aliased_table

        primary_key_foreign_key_pairs = primary_key.zip(foreign_key)
        constraints = primary_key_foreign_key_pairs.map do |join_primary_key, foreign_key|
          table[join_primary_key].eq(foreign_table[foreign_key])
        end.inject(&:and)

        if reflection.type
          if ActiveRecord::Base.store_base_sti_class
            value = transform_value(next_reflection.klass.polymorphic_name)
          else
            klass = next_reflection.klass
            value = ([klass] + klass.descendants).map(&:name)
          end
          scope = apply_scope(scope, table, reflection.type, value)
        end

        scope.joins!(join(foreign_table, constraints))
      end
    end

    HasManyThroughAssociation.class_eval do
      private

      def build_through_record(record)
        @through_records[record] ||= begin
          ensure_mutable

          attributes = through_scope_attributes
          attributes[source_reflection.name] = record

          through_association.build(attributes).tap do |new_record|
            if ActiveRecord::Base.store_base_sti_class
              new_record.send("#{source_reflection.foreign_type}=", options[:source_type]) if options[:source_type]
            end
          end
        end
      end
    end
  end

  Reflection::PolymorphicReflection.class_eval do
    private

    def source_type_scope
      type = @previous_reflection.foreign_type
      source_type = @previous_reflection.options[:source_type]
      unless ActiveRecord::Base.store_base_sti_class
        source_type = ([source_type.to_const] + source_type.to_const.descendants).map(&:to_s)
      end
      lambda { |object| where(type => source_type) }
    end
  end
end
