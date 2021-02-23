module Jobs
  class RejectedError < JobError
    def initialize(response, request)
      reason = Rack::Utils.status_reason(response.status.code)
      @name = "HTTP::#{reason.gsub(/\s|-|'/, '')}"
      @data = request
    end

    def backtrace
      caller_locations.drop(3)
    end
  end
end
