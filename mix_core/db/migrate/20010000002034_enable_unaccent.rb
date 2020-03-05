class EnableUnaccent < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'unaccent'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION unaccent_trigger() RETURNS TRIGGER AS $$
          DECLARE
            column TEXT;
            value TEXT;
            value_was TEXT;
            value_changed BOOLEAN = TRUE;
          BEGIN
            FOREACH column IN ARRAY TG_ARGV LOOP
              #{execute :get_value_cmd, 'column', 'value'}
              IF TG_OP = 'UPDATE' THEN
                #{execute :get_value_cmd, 'column', 'value_was', record: 'OLD'}
                #{value_changed? 'value'}
              END IF;
              IF value_changed AND value IS NOT NULL THEN
                NEW = NEW #= hstore(column, unaccent(value));
              END IF;
            END LOOP;

            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS unaccent_trigger();
        SQL
      end
    end
  end
end
