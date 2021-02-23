require 'http/response/status'

HTTP::Response::Status.class_eval do
  def job_accepted?
    success? || [460, 540].include?(code)
  end
end
