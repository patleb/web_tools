module MixJob
  has_config do
    attr_writer :parent_controller
    attr_writer :json_attributes
    attr_writer :available_queues

    def parent_controller
      @parent_controller ||= '::ActionController::API'
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
      @available_queues ||= HashWithIndifferentAccess.new(
        ActiveJob::Base.default_queue_name => 0,
      )
    end
  end
end
