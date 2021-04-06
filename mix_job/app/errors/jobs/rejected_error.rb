module Jobs
  class RejectedError < JobError
    def initialize(response, request)
      reason = Rack::Utils.status_reason(response.status.code)
      @name = "HTTP::#{reason.gsub(/\s|-|'/, '')}"
      @data = request
    end
  end
end
