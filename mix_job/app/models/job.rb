# frozen_string_literal: true

class Job < MixJob.config.parent_model.to_const!
  NOTIFY_CHANNEL = 'job_notify_channel'

  alias_attribute :provider_job_id, :id
  alias_attribute :enqueued_at, :created_at

  json_attribute MixJob.config.json_attributes

  enum queue_name: MixJob.config.available_queues

  with_options presence: true do
    validates :job_class
    validates :job_id
  end

  def self.path_regex
    @path_regex ||= Regexp.new("^#{path(job_class: '([\w:]+)', job_id: '([\w-]+)')}$")
  end

  def self.path(...)
    MixJob::Routes.job_path(...)
  end

  def self.url(...)
    MixJob::Routes.job_url(...)
  end

  def self.parse_notification(message)
    queue_i, scheduled_at, *_ = message.split(',')
    [queue_names.key(queue_i.to_i).to_s, Time.parse_utc(scheduled_at)]
  end

  def self.enqueue(attributes)
    attributes = attributes.except(:json_data, :id, :provider_job_id, :created_at, :enqueued_at)
    attributes.compact!
    create! attributes
  end

  def self.dequeue(name = ActiveJob::Base.default_queue_name)
    super(:queue_name, :priority, :scheduled_at) do |queue_name, priority, scheduled_at|
      <<-SQL
        WHERE #{queue_name} = #{queue_names[name]}
          AND #{scheduled_at} <= #{now_sql}
        ORDER BY #{priority} DESC, #{scheduled_at}
      SQL
    end
  end

  def request
    { url: url, data: data }
  end

  def url(**params)
    self.class.url(job_class: job_class, job_id: job_id, **params)
  end

  def data
    attributes = except(:json_data, :scheduled_at, :created_at, :enqueued_at).compact
    attributes[:provider_job_id] = attributes.delete(:id)
    attributes
  end
end
