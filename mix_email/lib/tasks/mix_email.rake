namespace :try do
  desc "-- [options] Try Send Email"
  task :send_email => :environment do
    email = (defined?(ApplicationMailer) ? ApplicationMailer : MainMailer).healthcheck
    email.deliver_now
  end
end
