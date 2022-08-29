module Sql::Reference::CounterCache
  extend ActiveSupport::Concern

  class_methods do
    def create_counter_cache(**)
      <<-SQL.strip_sql
        CREATE OR REPLACE FUNCTION counter_cache() RETURNS TRIGGER AS $$
        DECLARE
          foreign_key TEXT = quote_ident(TG_ARGV[0] || '_id');
          counter_name TEXT = quote_ident(TG_ARGV[1]);
          to_table TEXT = quote_ident(TG_ARGV[2]);
          target_id BIGINT;
          target_id_was BIGINT;
          target_id_changed BOOLEAN = FALSE;
          #{debug_var}
        BEGIN
          #{debug_init}
          IF TG_OP = 'UPDATE' THEN
            #{target_id_changed?}
          END IF;

          IF TG_OP = 'INSERT' OR target_id_changed THEN
            #{increment_target}
          END IF;

          IF TG_OP = 'DELETE' OR target_id_changed THEN
            #{decrement_target record: 'OLD'}
            IF NOT target_id_changed THEN
              RETURN OLD;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end

    def drop_counter_cache(**)
      "DROP FUNCTION IF EXISTS counter_cache"
    end

    # TODO --> ON TRUNCATE (what about partioned tables?)
    def create_counter_cache_trigger(from_table, ref_name, **options)
      counter_name = options.dig(:foreign_key, :counter_name) || "#{from_table}_count"
      to_table = options.dig(:foreign_key, :to_table) || ref_name.to_s.tableize
      <<-SQL.strip_sql
        CREATE CONSTRAINT TRIGGER #{counter_cache_trigger_name(from_table, ref_name)}
          AFTER INSERT OR UPDATE OR DELETE ON #{from_table}
          DEFERRABLE INITIALLY IMMEDIATE
          FOR EACH ROW EXECUTE PROCEDURE counter_cache('#{ref_name}', '#{counter_name}', '#{to_table}');
      SQL
    end

    def drop_counter_cache_trigger(from_table, ref_name, **)
      "DROP TRIGGER IF EXISTS #{counter_cache_trigger_name(from_table, ref_name)} ON #{from_table}"
    end

    def counter_cache_trigger_name(from_table, ref_name)
      "count_#{from_table}_of_#{ref_name}"[0..62]
    end

    def decrement_target(count = 1, **options)
      increment_target(-count, **options)
    end

    def increment_target(count = 1, **options)
      target_id = target_id_for(**options)
      <<-SQL.strip_sql
        #{get_target_id(**options)}
        IF #{target_id} IS NOT NULL THEN
          #{execute_increment_target count, **options}
        END IF;
      SQL
    end

    protected

    def execute_increment_target(count, to_table: 'to_table', **options)
      <<-SQL.strip_sql
        #{execute :increment_target_cmd, count, to_table, **options}
      SQL
    end

    private

    def increment_target_cmd(count, to_table, **options)
      target_id = target_id_for(**options)
      <<-SQL.compile_sql
        UPDATE [#{to_table}] SET [counter_name]=[counter_name]+[#{count}] WHERE id = $1 [USING #{target_id}]
      SQL
    end
  end
end
