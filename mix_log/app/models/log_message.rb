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

  attr_accessor :new_line_at

  scope :reportable, -> { where((column(:level) >= levels[:error]).and(column(:monitor).eq nil).or(column(:monitor).eq true)) }

  def self.select_by_hashes(log_id, levels, hashes)
    connection.exec_query(sanitize_sql_array([<<-SQL.strip_sql, hashes, levels, log_id]))
      SELECT #{table_name}.* FROM UNNEST(ARRAY[?]::TEXT[], ARRAY[?]::INTEGER[]) WITH ORDINALITY hashes(h, l, i)
        LEFT JOIN LATERAL (
          SELECT #{table_name}.* FROM #{table_name} WHERE log_id = ? AND text_hash = h AND level = l LIMIT 1
        ) #{table_name} ON TRUE
      ORDER BY i
    SQL
  end

  def self.report!
    if report?
      LogMailer.report.deliver_now
      reported!
    end
  end

  def self.report?
    report.any?
  end

  def self.report
    report_values[:messages]
  end

  def self.reported!
    report_values[:times].each do |(id, created_at)|
      where(id: id).update_all(line_at: created_at)
    end
  end

  def self.report_values
    m_access(:report_values) do
      times = []
      servers = report_rows.map do |message|
        times << [message.id, message.log_lines.maximum(:created_at)]
        [
          message.log.server.private_ip.to_s,
          message.level,
          message.updated_at,
          message.log_lines_type.demodulize,
          message.log.path,
          message.text_tiny
        ]
      end
      messages = servers.group_by(&:shift).transform_values! do |levels|
        levels.sort_by!(&:first).reverse.group_by(&:shift).transform_values! do |line_types|
          line_types.sort_by!(&:shift).reverse.map!(&:join!.with(' => '))
        end
      end
      { messages: messages, times: times }
    end
  end

  def self.report_rows
    reportable
      .includes(log: :server)
      .joins(:log_lines)
      .where(LogLine.column(:created_at) > column(:line_at))
      .order(updated_at: :desc) # :updated_at is the last time a log line has been added
      .distinct
  end
end
