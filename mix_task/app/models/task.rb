class Task < LibMainRecord
  include ActionView::Helpers::DateHelper

  has_userstamps

  enum! :name, MixTask.config.available_names
  enum  :state, {
    ready:     0,
    running:   1,
    success:   2,
    failure:   3,
    cancelled: 4,
    unknown:   5,
  }

  attribute :perform, :boolean
  attribute :from_later, :boolean

  validate :perform_later

  delegate :rake_tasks, to: :class

  def self.running?(name)
    where(name: name).running.exists?
  end

  def self.allowed_tasks
    case Current.user.as_role
    when :deployer then names.keys
    when :admin    then names.keys & MixTask.config.admin_names
    else []
    end
  end

  def self.rake_tasks
    return [] unless MixTask.config.yml_path.exist?
    @rake_tasks ||= YAML.safe_load(MixTask.config.yml_path.read, permitted_classes: [Symbol]) || {}
  end

  def self.to_yaml
    extract_tasks.pretty_yaml
  end

  def self.extract_tasks
    Rails.application.load_tasks
    names.each_with_object({}) do |(name, _), tasks|
      rake_task = Rake::Task[name]
      tasks[name] = { desc: rake_task.comment, args: rake_task.arg_names }
    end
  end

  def self.delete_or_create_all
    where.not(name: names.keys).delete_all
    names.keys.reverse_each do |name|
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

  def description
    rake_tasks[name][:desc]
  end

  def parameters
    rake_tasks[name][:args]
  end

  def allowed?
    self.class.allowed_tasks.include? name
  end

  def notify_editable?
    !running? || updater.nil? || updater == Current.user
  end

  def perform!
    update! perform: true, from_later: true
  rescue ActiveRecord::RecordInvalid
    save(validate: false)
    raise
  end

  private

  def perform_later
    return unless perform?
    return perform_now if from_later?

    clear_attribute_change :perform
    if notify_changed? && notify_editable?
      save(validate: false)
    end
    with_lock do
      if running?
        errors.add :base, :already_running
        throw :abort
      else
        TaskJob.perform_later(name)
        self.output = "[#{Time.current.utc}]#{Rake::RUNNING} #{name}"
        self.state = :running
      end
    end
  end

  def perform_now
    started_at = Concurrent.monotonic_time
    env = "PACK=false RAKE_OUTPUT=true NO_COLOR=true RAILS_ENV=#{Rails.env} RAILS_APP=#{Rails.app}"
    cmd = "#{env} bin/rake #{name}"
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
end
