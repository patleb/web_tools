module Sunzistrano::Context::WithJob
  def attributes
    super.merge! job_service: job_service
  end

  def job_service
    "#{stage}-job-#{job_queue}"
  end
end

Sunzistrano::Context.prepend Sunzistrano::Context::WithJob
