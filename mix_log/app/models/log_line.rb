class LogLine < LibRecord
  class IncompatibleLogLine < ::StandardError; end

  belongs_to :log
  belongs_to :log_label

  enum type: MixLog.config.available_types

  attr_readonly *%i(
    created_at
    type
  )

  # TODO send notification from here instead with monitor level check and if already alerted
  # TODO if in dev/test mode, output into the logs as well
  def self.push(log, line)
    line[:log_id] = log_id = log.id
    if (label = line.delete(:label))
      if (label = label.values_at(:text_hash, :text_tiny, :text, :level)).all? &:present?
        text_hash, text_tiny, text, level = convert_label(*label)
        log_label = LogLabel.find_or_create_by! log_id: log_id, level: level, text_hash: text_hash do |record|
          record..assign_attributes(text_tiny: text_tiny, text: text, log_lines_type: name)
        end
        line[:log_label_id] = log_label.id
      end
    end
    id = insert(line).pluck('id').first
    log_label.log_line_id = id if log_label
    log_label || id
  end

  def self.push_all(log, lines)
    log_id = log.id
    lines.each do |line|
      line[:log_id] = log_id
      line[:log_label_id] = nil
    end
    texts = lines.each_with_object([]).with_index do |(line, result), i|
      next unless (label = line.delete(:label))
      next unless (label = label.values_at(:text_hash, :text_tiny, :text, :level)).all? &:present?
      text_hash, text_tiny, text, level = convert_label(*label)
      result << {
        text_hash: text_hash, text_tiny: text_tiny, text: text,
        log_id: log_id, log_lines_type: name, level: level,
        line_i: i
      }
    end
    LogLabel.insert_all(texts.map(&:except.with(:line_i)).uniq(&:values_at.with(:text_hash, :level)))
    levels = texts.map(&:[].with(:level))
    hashes = texts.map(&:[].with(:text_hash))
    LogLabel.select_by_hashes(log_id, levels, hashes).pluck('id').each_with_index do |id, i|
      lines[texts[i][:line_i]][:log_label_id] = id
    end
    insert_all(lines)
  end

  def self.parse(log, line)
    raise NotImplementedError
  end

  def self.finalize
  end

  def self.squish(text)
    text.squish_numbers.squish!
  end

  def self.convert_label(text_hash, text_tiny, text, level)
    [Digest.md5_hex(text_hash), text_tiny[0...256], text, LogLabel.levels[level]]
  end

  def self.insert_all(attributes, **)
    attributes.each{ |row| row[:type] = name }
    super
  end
end
