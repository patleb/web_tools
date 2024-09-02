class LogLine < LibMainRecord
  class IncompatibleLogLine < ::StandardError; end

  belongs_to :log
  belongs_to :log_message

  enum! type: MixServer::Log.config.available_types

  attr_readonly *%i(
    created_at
    type
    pid
  )

  def self.apt_history(log)
    return unless Log.fs_types.include? 'LogLines::AptHistory'
    return unless (path = MixServer::Log.config.available_paths.find{ |path| path.end_with? 'apt/history.log'})
    apt_history_log = Log.find_or_create_by! server: log.server, path: path
    LogLines::AptHistory.where(log: apt_history_log)
  end

  def self.host(log)
    return unless Log.db_types.include? 'LogLines::Host'
    host_log = Log.find_or_create_by! server: log.server, log_lines_type: 'LogLines::Host'
    LogLines::Host.where(log: host_log)
  end

  def self.task(log)
    return unless Log.db_types.include? 'LogLines::Task'
    task_log = Log.find_or_create_by! server: log.server, log_lines_type: 'LogLines::Task'
    LogLines::Task.where(log: task_log)
  end

  def self.last_records(**conditions)
    query = where(log: Log.db_log(name))
    query = where(**conditions) if conditions.present?
    query.order(created_at: :desc)
  end

  def self.last_messages(text_tiny: nil, **conditions)
    query = LogMessage.all
    query = query.where('text_tiny LIKE ?', text_tiny) if text_tiny
    query = query.where(**conditions) if conditions.present?
    query.order(updated_at: :desc)
  end

  # :rollups groups must have their json_data keys in the same order/positions as :rollups_keys
  def self.rollups!(log, scope = :from_last, dry_run: false)
    groups = case scope
      when :all, true
        where(log: log).rollups
      when :from_last, false, nil
        period_at = rollups_class.where(log: log).order(period: :desc, period_at: :desc).pick(:period_at)
        period_at ? where(column(:created_at) >= period_at).where(log: log).rollups : where(log: log).rollups
      when Symbol
        public_send(scope).where(log: log).rollups
      end
    rows = groups.each_with_object([]) do |(key, values), result|
      period, group_name = key
      result.concat(values.map do |group_key, json_data|
        period_at, group_value = Array.wrap(group_key)
        json_data = Array.wrap(json_data)
        {
          group_name: group_name,
          group_value: group_value || '',
          period: 1.public_send(period),
          period_at: period_at,
          json_data: rollups_keys.first(json_data.size).zip(json_data).to_h
        }
      end)
    end
    rows.each do |row|
      row[:type] = rollups_class_name
      row[:log_id] = log.id
    end
    unless dry_run || rows.empty?
      rollups_class.upsert_all(rows, unique_by: 'index_lib_log_rollups_on_groups', returning: false)
    end
    rows
  end

  def self.rollups
    raise NotImplementedError
  end

  def self.rollups_type(i)
    Array.wrap(rollups_types[rollups_keys[i]]).first
  end

  def self.rollups_keys
    @rollups_keys ||= rollups_types.keys
  end

  def self.rollups_types
    rollups_class.json_attributes
  end

  def self.rollups_class
    rollups_class_name.to_const!
  end

  def self.rollups_class_name
    @rollups_class_name ||= "LogRollups::#{name.demodulize}"
  end

  def self.push(log, line)
    line[:created_at] ||= Time.current.utc
    line[:pid] ||= Process.pid
    line[:log_id] = log_id = log.id
    line[:json_data]&.reject!{ |_, v| v.blank? }
    log_message = nil
    with_message(line.delete(:message)) do |text_hash, text_tiny, text, level, monitor|
      log_message = LogMessage.find_or_create_by! level: level, text_hash: text_hash do |record|
        record.assign_attributes(text_tiny: text_tiny, text: text, monitor: monitor, log_lines_type: name)
      end
      log_message.update_columns monitor: monitor if log_message.monitor != monitor
      line[:log_message_id] = log_message.id
    end
    insert! line
    Log.increment_counter(:log_lines_count, log_id, touch: true)
    LogMessage.increment_counter(:log_lines_count, log_message.id, touch: true)
    log_message.new_line_at = line[:created_at]
    log_message
  end

  def self.push_all(log, lines)
    log_id = log.id
    unless Rails.env.local?
      log_server_created_at = log.server.created_at
      lines.reject! do |line|
        line[:created_at] < log_server_created_at
      end
      return if lines.empty?
    end
    lines.each do |line|
      line[:log_id] = log_id
      line[:json_data]&.reject!{ |_, v| v.blank? }
      line[:log_message_id] = nil
    end
    texts = lines.each_with_object([]).with_index do |(line, result), i|
      with_message(line.delete(:message)) do |text_hash, text_tiny, text, level, monitor|
        result << {
          text_hash: text_hash, text_tiny: text_tiny, text: text,
          log_lines_type: name, level: level, monitor: monitor,
          line_i: i
        }
      end
    end
    LogMessage.insert_all(texts.map(&:except.with(:line_i)).uniq(&:values_at.with(:text_hash, :level)))
    levels = texts.map(&:[].with(:level))
    hashes = texts.map(&:[].with(:text_hash))
    log_messages = LogMessage.select_by_hashes(levels, hashes).pluck('id')
    log_messages.each_with_index do |id, i|
      lines[texts[i][:line_i]][:log_message_id] = id
    end
    insert_all! lines
    Log.update_counters(log_id, log_lines_count: lines.size, touch: true)
    log_messages.tally.each do |id, count|
      LogMessage.update_counters(id, log_lines_count: count, touch: true)
    end
  rescue JSON::GeneratorError, ActiveRecord::StatementInvalid, LogLine::IncompatibleLogLine
    lines.each do |line|
      push(log, line)
    rescue JSON::GeneratorError, ActiveRecord::StatementInvalid, LogLine::IncompatibleLogLine => e
      save_and_filter_unknown(line.merge(error: e.class.name).pretty_hash!)
    end
  end

  def self.parse(log, line, **)
    raise NotImplementedError
  end

  def self.finalize(log)
  end

  def self.save_and_filter_unknown(line, created_at = nil)
    unknown = LogUnknown.find_or_create_by! text_hash: Digest.sha256_hex(squish(line)) do |record|
      record.assign_attributes text: line, log_lines_type: name
    end
    unknown.increment! :log_lines_count, touch: true
    { created_at: created_at, filtered: true }
  end

  def self.squish(text)
    text.squish_all
  end

  def self.with_message(message)
    unless message && (message = message.values_at(:monitor, :text_hash, :text_tiny, :text, :level)).last(2).all?(&:present?)
      raise IncompatibleLogLine, message.try(:pretty_json) || message
    end
    monitor, text_hash, text_tiny, text, level = message
    text_tiny ||= squish(text)
    text_hash ||= text_tiny
    yield Digest.sha256_hex(text_hash), text_tiny[0...256], text, LogMessage.levels[level], monitor
  end

  def self.merge_paths(paths)
    tokens = paths.each_with_object([]) do |path, memo|
      path.split('/').each_with_index do |token, i|
        (memo[i] ||= Set.new) << token
      end
    end
    tokens = tokens.map(&:to_a).map do |token|
      token.size > 1 ? "{#{token.join(',')}}" : token.first
    end
    tokens.join('/')
  end
end
