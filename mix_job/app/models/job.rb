class Job < LibRecord
  NOTIFY_CHANNEL = 'job_notify_channel'.freeze

  alias_attribute :provider_job_id, :id
  alias_attribute :enqueued_at, :created_at
  alias_attribute :time_zone, :timezone

  json_attribute MixJob.config.json_attributes

  enum queue_name: MixJob.config.available_queues

  with_options presence: true do
    validates :job_class
    validates :job_id
  end

  def self.url(job_class: nil, job_id: nil, **params)
    url = (@url ||= Rails.application.routes.url_helpers.jobs_url(job_class: '__JOB_CLASS__', job_id: '__JOB_ID__'))
    if job_class && job_id
      url = url.sub('__JOB_CLASS__', job_class).sub('__JOB_ID__', job_id)
      params.any? ? "#{url}?#{params.to_query}" : url
    else
      url
    end
  end

  def self.parse_notification(message)
    queue_i, scheduled_at, *_ = message.split(',')
    [queue_names.key(queue_i.to_i), Time.parse(scheduled_at)]
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
    attributes = except(:json_data, :scheduled_at, :created_at, :enqueued_at).compact!
    attributes[:provider_job_id] = attributes.delete(:id)
    attributes
  end
end
