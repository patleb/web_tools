module Jobs
  class InvalidError < JobError
    def initialize(job, params)
      super(ActiveRecord::RecordInvalid.new(job), data: params)
    end

    def backtrace
      caller_locations.drop(4)
    end
  end
end
