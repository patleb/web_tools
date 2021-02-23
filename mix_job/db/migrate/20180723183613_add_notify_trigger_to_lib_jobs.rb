### References
# https://gist.github.com/bithavoc/f40bbc33b553f2fddf9e1095858acdff
# https://gist.github.com/colophonemes/9701b906c5be572a40a84b08f4d2fa4e
class AddNotifyTriggerToLibJobs < ActiveRecord::Migration[6.0]
  def up
    exec_query <<-SQL.strip_sql
      CREATE OR REPLACE FUNCTION job_notify() RETURNS trigger AS $$
        BEGIN
          PERFORM pg_notify('#{Job::NOTIFY_CHANNEL}', NEW.queue_name::TEXT || ',' || NEW.scheduled_at::TEXT || ' UTC');
          RETURN NEW;
        END;
      $$ LANGUAGE plpgsql;
    SQL

    exec_query <<-SQL.strip_sql
      CREATE TRIGGER job_notify_trigger
        AFTER INSERT OR UPDATE ON lib_jobs
        FOR EACH ROW EXECUTE PROCEDURE job_notify();
    SQL
  end

  def down
    exec_query("DROP TRIGGER IF EXISTS job_notify_trigger ON lib_jobs")
    exec_query("DROP FUNCTION IF EXISTS job_notify()")
  end
end
