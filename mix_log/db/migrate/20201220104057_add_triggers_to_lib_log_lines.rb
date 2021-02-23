class AddTriggersToLibLogLines < ActiveRecord::Migration[6.0]
  def change
    add_counter_cache :lib_log_lines, :log, foreign_key: { to_table: :lib_logs, counter_name: :log_lines_count }
    add_counter_cache :lib_log_lines, :log_message, foreign_key: { to_table: :lib_log_messages, counter_name: :log_lines_count }
  end
end
