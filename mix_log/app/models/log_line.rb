class LogLine < LibRecord
  class IncompatibleLogLine < ::StandardError; end

  belongs_to :log
  belongs_to :log_label

  enum type: MixLog.config.available_types

  attr_readonly *%i(
    created_at
    type
    pid
  )

  def self.push(log, line)
    line[:log_id] = log_id = log.id
    line[:json_data]&.reject!{ |_, v| v.blank? }
    log_label = nil
    with_label(line.delete(:label)) do |text_hash, text_tiny, text, level|
      log_label = LogLabel.find_or_create_by! log_id: log_id, level: level, text_hash: text_hash do |record|
        record.assign_attributes(text_tiny: text_tiny, text: text, log_lines_type: name)
      end
      line[:log_label_id] = log_label.id
    end
    id = insert(line).pluck('id').first
    log_label.log_line_id = id if log_label
    log_label || id
  end

  def self.push_all(log, lines)
    log_id = log.id
    lines.each do |line|
      line[:log_id] = log_id
      line[:json_data]&.reject!{ |_, v| v.blank? }
      line[:log_label_id] = nil
    end
    texts = lines.each_with_object([]).with_index do |(line, result), i|
      with_label(line.delete(:label)) do |text_hash, text_tiny, text, level|
        result << {
          text_hash: text_hash, text_tiny: text_tiny, text: text,
          log_id: log_id, log_lines_type: name, level: level,
          line_i: i
        }
      end
    end
    LogLabel.insert_all(texts.map(&:except.with(:line_i)).uniq(&:values_at.with(:text_hash, :level)))
    levels = texts.map(&:[].with(:level))
    hashes = texts.map(&:[].with(:text_hash))
    LogLabel.select_by_hashes(log_id, levels, hashes).pluck('id').each_with_index do |id, i|
      lines[texts[i][:line_i]][:log_label_id] = id
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

  def self.with_label(label)
    return unless label && (label = label.values_at(:text_hash, :text_tiny, :text, :level)).last(2).all?(&:present?)
    text_hash, text_tiny, text, level = label
    text_tiny ||= squish(text)
    text_hash ||= text_tiny
    yield Digest.md5_hex(text_hash), text_tiny[0...256], text, LogLabel.levels[level]
  end

  def self.insert_all(attributes, **)
    attributes.each{ |row| row[:type] = name }
    super
  end
end
