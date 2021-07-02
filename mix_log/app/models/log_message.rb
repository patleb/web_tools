# TODO NginxAccess[status, method, path] --> SELECT * FROM UNNEST((regexp_split_to_array(text_tiny, ' '))[1:3])
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

  scope :reportable, -> { where((column(:level) >= levels[:error]).and(column(:monitor).eq nil).or(column(:monitor).eq true)).where(alerted: false) }

  def self.select_by_hashes(log_id, levels, hashes)
    connection.exec_query(sanitize_sql_array([<<-SQL.strip_sql, hashes, levels, log_id]))
      SELECT #{table_name}.* FROM UNNEST(ARRAY[?]::TEXT[], ARRAY[?]::INTEGER[]) WITH ORDINALITY hashes(h, l, i)
        LEFT JOIN LATERAL (
          SELECT #{table_name}.* FROM #{table_name} WHERE log_id = ? AND text_hash = h AND level = l LIMIT 1
        ) #{table_name} ON TRUE
      ORDER BY i
    SQL
  end

  def self.report!(...)
    if report? ...
      LogMailer.report(...).deliver_now
      reported! ...
    end
  end

  def self.report(...)
    report_ids(...).first
  end

  def self.report?(...)
    report_ids(...).last.any?
  end

  def self.reported!(...)
    where(id: report_ids(...).last).update_all(alerted: true)
  end

  def self.report_ids(since = nil)
    since = since.beginning_of_day if since
    m_access(:report_ids, since) do
      messages = reportable.includes(log: :server)
      messages = messages.joins(:log_lines).where(LogLine.table_name => { created_at: since..Time.current }) if since
      ids = []
      servers = messages.order(updated_at: :desc).map do |message|
        ids << message.id
        [
          message.log.server.private_ip.to_s,
          message.level,
          message.updated_at,
          message.log_lines_type.demodulize,
          message.log.path,
          message.text_tiny
        ]
      end
      report = servers.group_by(&:shift).transform_values! do |levels|
        levels.sort_by!(&:first).reverse.group_by(&:shift).transform_values! do |line_types|
          line_types.sort_by!(&:shift).reverse.map!(&:join!.with(' => '))
        end
      end
      [report, ids]
    end
  end
end
