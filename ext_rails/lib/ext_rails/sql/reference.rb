module Sql::Reference
  extend ActiveSupport::Concern

  require_rel 'reference'

  included do
    # foreign_key: {...}          --> :dependent
    prepend self::CounterCache #  --> :counter_cache
    prepend self::Touch        #  --> :touch
  end

  class_methods do
    def target_id_changed?
      <<-SQL.strip_sql
        #{get_target_id record: 'NEW'}
        #{get_target_id record: 'OLD'}
        #{value_changed? 'target_id'}
      SQL
    end

    def get_target_id(**options)
      target_id = target_id_for(**options)
      <<-SQL.strip_sql
        IF #{target_id} IS NULL THEN
          #{execute :get_value_cmd, 'foreign_key', target_id, **options}
        END IF;
      SQL
    end

    private

    def target_id_for(record: 'NEW', **)
      record == 'OLD' ? 'target_id_was' : 'target_id'
    end
  end
end
