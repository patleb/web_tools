class JobsController < LibApiController
  class ForbiddenRemoteIp < ::StandardError; end

  skip_forgery_protection

  before_action :local_request!

  def create
    job = Job.new(params.require(:job).to_unsafe_h)
    if job.valid?
      ActiveJob::Base.execute(job.data)
      head :created
    else
      log Jobs::InvalidError.new(job, params.to_unsafe_h)
      head :job_client_error
    end
  rescue Exception => exception
    log JobError.new(exception, data: params.to_unsafe_h)
    head :job_server_error
  end

  private

  def local_request!
    return if request.local?
    log ForbiddenRemoteIp.new("[#{request.remote_ip}]")
    head :forbidden
  end
end
