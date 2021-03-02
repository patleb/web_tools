ActionMailer::Base.class_eval do
  self.deliver_later_queue_name = ActiveJob::Base.default_queue_name
end
