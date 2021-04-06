module Jobs
  class InvalidError < JobError
    def initialize(job, params)
      super(ActiveRecord::RecordInvalid.new(job), data: params)
    end
  end
end
