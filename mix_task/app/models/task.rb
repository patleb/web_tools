class Task < LibMainRecord
  include ActionView::Helpers::DateHelper

  has_userstamps

  enum! name: MixTask.config.available_names
  enum  state: {
    ready: 0,
    running: 1,
    success: 2,
    failure: 3,
    cancelled: 4,
    unknown: 5,
  }

  attribute :_perform, :boolean
  attribute :_from_later, :boolean

  validate :perform_later

  def self.running?(name)
    where(name: name).take&.running?
  end

  def self.perform(name, *arguments)
    find(name).update! arguments: arguments, _perform: true
  end

  def self.visible_tasks
    return names.keys if Current.user.deployer?
    return names.keys & MixTask.config.admin_names if Current.user.admin?
    return []
  end

  def self.delete_or_create_all
    where.not(name: names.keys).delete_all
    names.each_key do |name|
      task = find_or_initialize_by(name: name)
      task.save(validate: false)
    end
  end

  def self.path(name)
    MixAdmin::Routes.edit_path(model_name: self.name.to_class_param, id: name)
  end

  def path
    self.class.path(name)
  end

  def duration_avg
    distance_of_time(durations.average.seconds) unless durations.empty?
  end

  def duration
    distance_of_time(durations.last.seconds)
  end

  def parameters
    rake_task.arg_names
  end

  def description
    rake_task.comment
  end

  def visible?
    self.class.visible_tasks.include? name
  end

  def arguments_visible?
    arguments.any?(&:present?) # TODO should be parameters --> add config
  end

  def notify_editable?
    !running? || updater.nil? || updater.id == Current.user.id
  end

  def perform(arguments)
    update! arguments: arguments, _perform: true, _from_later: true
  rescue ActiveRecord::RecordInvalid
    save(validate: false)
    raise
  end

  private

  def perform_later
    return unless _perform?
    return perform_now if _from_later?

    clear_attribute_change :_perform
    if notify_changed? && notify_editable?
      save(validate: false)
    end
    with_lock do
      if running?
        errors.add :base, :already_running
        throw :abort
      else
        Current.flash_later = true
        TaskJob.perform_later(name, *arguments)
        self.output = "[#{Time.current.utc}]#{Rake::RUNNING} #{name}"
        self.state = :running
      end
    end
  end

  def perform_now
    started_at = Concurrent.monotonic_time
    args = "[#{arguments.map{ |arg| "'#{arg.escape_single_quotes}'" if arg.present? }.join(',')}]" if arguments.any?
    env = "RAKE_OUTPUT=true DISABLE_COLORIZATION=true RAILS_ENV=#{Rails.env} RAILS_APP=#{Rails.app}"
    cmd = "#{env} bin/rake #{name}#{args}"
    self.output, status = Open3.capture2e(cmd)

    result = output.lines.reject(&:blank?).last
    case
    when result&.include?(Rake::FAILURE) || status != 0
      set_error_state :failure
    when output&.include?(Rake::CANCEL)
      set_error_state :cancelled
    when result&.include?(Rake::SUCCESS)
      durations.shift until durations.size < MixTask.config.durations_max_size
      self.durations << (Concurrent.monotonic_time - started_at).seconds.ceil(3)
      self.state = :success
    else
      set_error_state :unknown
    end
  end

  def set_error_state(type)
    errors.add :base, type
    self.state = type
  end

  def rake_task
    @rake_task ||= Rake::Task[name]
  end
end
