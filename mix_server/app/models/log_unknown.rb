class LogUnknown < LibMainRecord
  enum! :log_lines_type, MixServer::Logs.config.available_types

  def self.report?
    report > 0
  end

  def self.report
    report_values[:count]
  end

  def self.reported!
    Global[:log_unknowns_at] = Time.current if report?
  end

  def self.report_values
    m_access(__method__) do
      { count: LogUnknown.where(column(:updated_at) > Global.fetch(:log_unknowns_at){ Time.at(0) }).count }
    end
  end

  def reported?
    Global[:log_unknowns_at] && Global[:log_unknowns_at] > updated_at
  end
end
