module ActiveJob::Base::WithJob
  extend ActiveSupport::Concern

  prepended do
    attr_accessor :session_id
    attr_accessor :request_id
  end

  class_methods do
    def context
      @context ||= %i(locale timezone session_id request_id)
    end

    def deserialize(job_data)
      job = job_data["job_class"].to_const!.new
      job.deserialize(job_data)
    end
  end

  def initialize(*arguments)
    super
    @session_id = Current.session_id
    @request_id = Current.request_id
  end

  def serialize
    super.merge!(
      "session_id" => session_id,
      "request_id" => request_id,
    )
  end

  def deserialize(job_data)
    super
    self.session_id = job_data["session_id"]
    self.request_id = job_data["request_id"]
  end

  def perform_now
    old_attributes = Current.attributes.dup
    self.class.context.each do |attribute|
      Current[attribute] = send(attribute)
    end
    super
  ensure
    Current.attributes = old_attributes
  end
end
