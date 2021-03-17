namespace :try do
  desc "try send email later"
  task :send_email_later => :environment do
    run_task 'try:send_email', :later
  end

  desc "try send email"
  task :send_email, [:later] => :environment do |t, args|
    email = (defined?(ApplicationMailer) ? ApplicationMailer : MainMailer).healthcheck
    if flag_on? args, :later
      email.deliver_later
    else
      email.deliver_now
    end
  end
end
