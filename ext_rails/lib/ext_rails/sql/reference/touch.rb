module Sql::Reference::Touch
  extend ActiveSupport::Concern

  class_methods do
    def create_touch(**)
      <<-SQL.strip_sql
        CREATE OR REPLACE FUNCTION touch() RETURNS TRIGGER AS $$
        DECLARE
          foreign_key TEXT = quote_ident(TG_ARGV[0] || '_id');
          target_updated_at TIMESTAMP;
          to_table TEXT = quote_ident(TG_ARGV[1]);
          target_id BIGINT;
          target_id_was BIGINT;
          target_id_changed BOOLEAN = FALSE;
          #{debug_var}
        BEGIN
          #{debug_init}
          IF TG_OP = 'UPDATE' THEN
            #{target_id_changed?}
            IF NOT target_id_changed THEN
              #{touch_target}
            END IF;
          END IF;

          IF TG_OP = 'INSERT' OR target_id_changed THEN
            #{touch_target}
          END IF;

          IF TG_OP = 'DELETE' OR target_id_changed THEN
            #{touch_target record: 'OLD'}
            IF NOT target_id_changed THEN
              RETURN OLD;
            END IF;
          END IF;

          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end

    def drop_touch(**)
      "DROP FUNCTION IF EXISTS touch"
    end

    def create_touch_trigger(from_table, ref_name, **options)
      to_table = options.dig(:foreign_key, :to_table) || ref_name.to_s.tableize
      <<-SQL.strip_sql
        CREATE CONSTRAINT TRIGGER #{touch_trigger_name(from_table, ref_name)}
          AFTER INSERT OR UPDATE OR DELETE ON #{from_table}
          DEFERRABLE INITIALLY IMMEDIATE
          FOR EACH ROW EXECUTE PROCEDURE touch('#{ref_name}', '#{to_table}');
      SQL
    end

    def drop_touch_trigger(from_table, ref_name, **)
      "DROP TRIGGER IF EXISTS #{touch_trigger_name(from_table, ref_name)} ON #{from_table}"
    end

    def touch_trigger_name(from_table, ref_name)
      "touch_#{ref_name}_of_#{from_table}"[0..62]
    end

    def touch_target(**options)
      target_id = target_id_for(**options)
      <<-SQL.strip_sql
        #{get_target_id **options}
        IF #{target_id} IS NOT NULL THEN
          #{get_target_updated_at}
          #{execute_touch_target **options}
        END IF;
      SQL
    end

    def get_target_updated_at
      <<-SQL.strip_sql
        SELECT NULLIF(current_setting('touch.timestamp', TRUE), '') INTO target_updated_at;
        IF target_updated_at IS NULL THEN
          SELECT set_config('touch.timestamp', #{current_timestamp}::TEXT, TRUE) INTO target_updated_at;
        END IF;
      SQL
    end

    protected

    def execute_touch_target(to_table: 'to_table', **options)
      <<-SQL.strip_sql
        #{execute :touch_target_cmd, to_table, **options}
      SQL
    end

    private

    def touch_target_cmd(to_table, **options)
      target_id = target_id_for(**options)
      <<-SQL.compile_sql
        UPDATE [#{to_table}] SET updated_at = $2
          WHERE id = $1 AND updated_at < $2 [USING #{target_id}, target_updated_at]
      SQL
    end

    def current_timestamp
      if Rails.env.test?
        "(CURRENT_TIMESTAMP + (random() * (CURRENT_TIMESTAMP + '30 minutes'::INTERVAL - CURRENT_TIMESTAMP)) + '1 minute'::INTERVAL)"
      else
        'CURRENT_TIMESTAMP'
      end
    end
  end
end
