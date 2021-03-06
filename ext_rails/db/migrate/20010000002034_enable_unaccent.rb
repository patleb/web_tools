class EnableUnaccent < ActiveRecord::Migration[6.0]
  def change
    # Note --> for accent-insensitive search, add an index with unaccent(col)
    enable_extension 'unaccent'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION unaccent_text() RETURNS TRIGGER AS $$
          DECLARE
            column_name TEXT;
            value TEXT;
            value_was TEXT;
            value_changed BOOLEAN = TRUE;
          BEGIN
            FOREACH column_name IN ARRAY TG_ARGV LOOP
              #{Sql.execute :get_value_cmd, 'column_name', 'value'}
              IF TG_OP = 'UPDATE' THEN
                #{Sql.execute :get_value_cmd, 'column_name', 'value_was', record: 'OLD'}
                #{Sql.value_changed? 'value'}
              END IF;
              IF value_changed AND value IS NOT NULL THEN
                NEW = NEW #= hstore(column_name, unaccent(value));
              END IF;
            END LOOP;

            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS unaccent_text();
        SQL
      end
    end
  end
end
