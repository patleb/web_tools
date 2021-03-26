class LogLine < LibRecord # TODO https://pgdash.io/blog/postgres-observability.html
  class IncompatibleLogLine < ::StandardError; end
  class DuplicatePartition < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message.match? /PG::DuplicateTable/
    end
  end
  class MissingPartition < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message.match? /no partition of relation "#{LogLine.table_name}" found for row/
    end
  end

  belongs_to :log
  belongs_to :log_message

  enum type: MixLog.config.available_types

  attr_readonly *%i(
    created_at
    type
    pid
  )

  def self.rollups!(scope = :from_last)
    rollups_class_name = "LogRollups::#{name.demodulize}"
    rollups_class = rollups_class_name.to_const!
    rows = case scope
      when :all, true
        rollups
      when :from_last, false, nil
        period_at = rollups_class.order(period: :desc, period_at: :desc).pick(:period_at)
        period_at ? where(column(:created_at) >= period_at).rollups : rollups
      when Symbol
        send(scope).rollups
      end
    rows.each{ |row| row[:type] = rollups_class_name }
    rollups_class.upsert_all(rows, unique_by: 'index_lib_log_rollups_on_groups', returning: false) if rows.any?
    rows
  end

  def self.rollups
    raise NotImplementedError
  end

  def self.push(log, line)
    line[:created_at] ||= Time.current.utc
    line[:log_id] = log_id = log.id
    line[:json_data]&.reject!{ |_, v| v.blank? }
    log_message = nil
    with_message(line.delete(:message)) do |text_hash, text_tiny, text, level|
      log_message = LogMessage.find_or_create_by! log_id: log_id, level: level, text_hash: text_hash do |record|
        record.assign_attributes(text_tiny: text_tiny, text: text, log_lines_type: name)
      end
      line[:log_message_id] = log_message.id
    end
    id = insert(line).pluck('id').first
    log_message.log_line_id = id if log_message
    log_message || id
  end

  def self.push_all(log, lines)
    log_id = log.id
    lines.each do |line|
      line[:log_id] = log_id
      line[:json_data]&.reject!{ |_, v| v.blank? }
      line[:log_message_id] = nil
    end
    texts = lines.each_with_object([]).with_index do |(line, result), i|
      with_message(line.delete(:message)) do |text_hash, text_tiny, text, level|
        result << {
          text_hash: text_hash, text_tiny: text_tiny, text: text,
          log_id: log_id, log_lines_type: name, level: level,
          line_i: i
        }
      end
    end
    LogMessage.insert_all(texts.map(&:except.with(:line_i)).uniq(&:values_at.with(:text_hash, :level)))
    levels = texts.map(&:[].with(:level))
    hashes = texts.map(&:[].with(:text_hash))
    LogMessage.select_by_hashes(log_id, levels, hashes).pluck('id').each_with_index do |id, i|
      lines[texts[i][:line_i]][:log_message_id] = id
    end
    insert_all(lines)
  end

  def self.parse(log, line, **)
    raise NotImplementedError
  end

  def self.finalize
  end

  def self.squish(text)
    text.squish_numbers.squish!
  end

  def self.with_message(message)
    return unless message && (message = message.values_at(:text_hash, :text_tiny, :text, :level)).last(2).all?(&:present?)
    text_hash, text_tiny, text, level = message
    text_tiny ||= squish(text)
    text_hash ||= text_tiny
    yield Digest.sha1_hex(text_hash), text_tiny[0...256], text, LogMessage.levels[level]
  end

  def self.insert_all!(attributes, **)
    attributes.each{ |row| row[:type] = name }
    with_partition(attributes){ super }
  end

  def self.insert_all(attributes, **)
    attributes.each{ |row| row[:type] = name }
    with_partition(attributes){ super }
  end

  def self.upsert_all(attributes, **)
    attributes.each{ |row| row[:type] = name }
    with_partition(attributes){ super }
  end

  def self.with_partition(attributes)
    yield
  rescue MissingPartition
    attributes.each{ |row| create_partition(row[:created_at]) }
    retry
  end

  def self.create_partition(date)
    partition = partition_for(date)
    return if partitions.include? partition[:name]
    connection.exec_query("CREATE TABLE #{partition[:name]} PARTITION OF #{table_name} FOR VALUES FROM ('#{partition[:from]}') TO ('#{partition[:to]}')")
    m_clear(:partitions)
  rescue DuplicatePartition
    m_clear(:partitions)
  end

  def self.drop_partition(date)
    connection.exec_query("DROP TABLE IF EXISTS #{partition_for(date)[:name]}")
    m_clear(:partitions)
  end

  def self.partitions_dates
    partitions.map{ |name| Time.find_zone('UTC').parse(name[/\d{4}_\d{2}_\d{2}$/].dasherize).utc }
  end

  def self.partitions
    m_access(:partitions) do
      connection.select_values("SELECT inhrelid::regclass FROM pg_catalog.pg_inherits WHERE inhparent = '#{table_name}'::regclass ORDER BY 1")
    end
  end

  def self.partition_for(date)
    date = date.send("beginning_of_#{MixLog.config.partition_interval_type}")
    from_date = date.strftime('%Y_%m_%d')
    next_date = (date + MixLog.config.partition_interval).strftime('%Y_%m_%d')
    partition = "#{table_name}_#{from_date}"
    { name: partition, from: from_date, to: next_date }
  end
end
