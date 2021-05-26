class Log < LibMainRecord
  FS_TYPE = %r{(?:/log|/(\w+)|)/(?:\w+\.)?(?:(\w+)\.log|(\w+log))$}

  belongs_to :server
  has_many   :log_lines
  has_many   :log_messages

  enum log_lines_type: MixLog.config.available_types

  attr_readonly *%i(
    log_lines_type
    path
  )

  before_create :initialize_log_lines_type, if: -> { path.present? }

  def self.db_log(db_type)
    (@db_log ||= {})[db_type] ||= find_or_create_by! server: Server.current, log_lines_type: db_type
  end

  def self.db_types
    fs_types = MixLog.config.available_paths.map(&singleton_method(:fs_type))
    MixLog.config.available_types.except(*fs_types).keys
  end

  def self.fs_type(path)
    name = path.match(FS_TYPE).captures.join('_')
    name == Rails.env ? 'LogLines::Rails' : "LogLines::#{name.camelize}"
  end

  db_types.each do |db_type|
    define_singleton_method db_type.demodulize.underscore do |*args, **options, &block|
      db_log(db_type).push(*args, **options, &block)
    end
  end

  def push(*args, **options, &block)
    log_lines_type.to_const!.push(self, *args, **options, &block)
  end

  def push_all(lines)
    log_lines_type.to_const!.push_all(self, lines)
  end

  def parse(line, **options)
    log_lines_type.to_const!.parse(self, line, **options)
  end

  def finalize
    log_lines_type.to_const!.finalize
  end

  def rotated_files
    Pathname.glob("#{path}.*").sort_by(&:mtime) # older files first
  end

  private

  def initialize_log_lines_type
    self.log_lines_type ||= self.class.fs_type(path)
  end
end
