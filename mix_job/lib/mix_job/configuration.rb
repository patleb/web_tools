MonkeyPatch.add{['activejob', 'lib/active_job/queue_name.rb', 'b473689c7e9b0b6424751c1b2500660bd374a1b829822c4634c6771f0a03edea']}

module MixJob
  has_config do
    attr_writer :async
    attr_writer :parent_controller
    attr_writer :json_attributes
    attr_writer :available_queues

    def async?
      @async
    end

    def parent_controller
      @parent_controller ||= 'ActionController::API'
    end

    def json_attributes
      @json_attributes ||= {
        job_class: :string,
        job_id: :string,
        session_id: :string,
        request_id: :string,
        arguments: :json,
        executions: :integer,
        exception_executions: :json,
        locale: :string,
        timezone: :string,
      }
    end

    def available_queues
      @available_queues ||= {
        ActiveJob::Base.default_queue_name => 0,
      }.with_indifferent_access
    end
  end
end
