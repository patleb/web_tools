MonkeyPatch.add{['activejob', 'lib/active_job/core.rb', '718ce689f7e5ef955934f86d419c9571f32341c8091f0a5baaffc8f0727d2bf8']}

module ActiveJob::Base::WithContext
  extend ActiveSupport::Concern

  prepended do
    attr_writer   :context
    attr_accessor :session_id
    attr_accessor :request_id
  end

  class_methods do
    def deserialize(job_data)
      job = job_data['job_class'].to_const!.new
      job.deserialize(job_data)
      job
    end
  end

  def initialize(*arguments)
    super
    @session_id = Current.session_id
    @request_id = Current.request_id
  end

  def context
    @context ||= []
  end

  def serialize
    super.merge!(
      'session_id' => session_id,
      'request_id' => request_id,
    )
  end

  def deserialize(job_data)
    super
    self.session_id = job_data['session_id']
    self.request_id = job_data['request_id']
    context.concat %i(locale timezone session_id request_id)
  end

  def perform_now
    old_attributes = Current.attributes.dup
    context.each do |attribute|
      Current[attribute] = public_send(attribute)
    end
    super
  ensure
    Current.attributes = old_attributes
  end
end
