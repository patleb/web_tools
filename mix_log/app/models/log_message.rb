class LogMessage < LibMainRecord
  belongs_to :log
  has_many   :log_lines

  class << self
    undef_method :warn # defined in Kernel
  end

  enum level: {
    debug:   0,
    info:    1,
    warn:    2,
    error:   3,
    fatal:   4,
    unknown: 5,
  }
  enum log_lines_type: MixLog.config.available_types

  attr_accessor :log_line_id

  # TODO NginxAccess[status, method, path] --> SELECT * FROM UNNEST((regexp_split_to_array(text_tiny, ' '))[1:3])

  def self.select_by_hashes(log_id, levels, hashes)
    connection.exec_query(sanitize_sql_array([<<-SQL.strip_sql, hashes, levels, log_id]))
      SELECT #{table_name}.* FROM UNNEST(ARRAY[?]::TEXT[], ARRAY[?]::INTEGER[]) WITH ORDINALITY hashes(h, l, i)
        LEFT JOIN LATERAL (
          SELECT #{table_name}.* FROM #{table_name} WHERE log_id = ? AND text_hash = h AND level = l LIMIT 1
        ) #{table_name} ON TRUE
      ORDER BY i
    SQL
  end

  def self.last_updated_at(db_type, text_tiny:)
    where(log: Log.db_log(db_type)).where('text_tiny LIKE ?', text_tiny).order(updated_at: :desc).pick(:updated_at)
  end
end
