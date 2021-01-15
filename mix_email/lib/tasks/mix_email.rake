namespace :try do
  desc "try send email"
  task :send_email => :environment do
    email = (defined?(ApplicationMailer) ? ApplicationMailer : MainMailer).healthcheck
    email.deliver_now
  end
end
