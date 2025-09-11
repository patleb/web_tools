require_dir __FILE__, 'ext_rails'

desc 'run "Some.ruby(code)" or filename.rb'
task :runner, [:code_or_file] => :environment do |t, args|
  if (file = args[:code_or_file])&.end_with? '.rb'
    load file
  elsif (code = args[:code_or_file])&.include? '.'
    eval code, TOPLEVEL_BINDING, __FILE__, __LINE__
  else
    raise "Invalid ruby code or filename"
  end
end

namespace :list do
  desc 'reorganize lists'
  task :reorganize => :environment do |t|
    Rails.application.eager_load!
    ActiveRecord::Base.listables.each(&:list_reorganize)
  end
end

namespace :try do
  %w(raise_exception sleep sleep_long).each do |name|
    desc "try #{name.tr('_', ' ')}"
    task name.to_sym => :environment do |t|
      "Try::#{name.camelize}".constantize.new(self, t).run!
    end
  end

  desc "try send email later"
  task :send_email_later => :environment do
    run_rake 'try:send_email', :later
  end

  desc "try send email"
  task :send_email, [:later] => :environment do |t, args|
    email = (defined?(ApplicationMailer) ? ApplicationMailer : LibMailer).healthcheck
    if flag_on? args, :later
      email.deliver_later
    else
      email.deliver_now
    end
  end

  desc "try private ip"
  task :private_ip => :environment do
    puts Process.host.private_ip
  end

  namespace :cluster do
    desc "try cluster private ip"
    task :private_ip => :environment do
      sun_rake 'try:private_ip'
    end
  end
end

namespace :gem do
  desc 'destroy gem'
  task :destroy, [:name] do |t, args|
    name = args[:name]
    except = ENV['EXCEPT'].to_s.split(',')
    `gem list -r '^#{name}$' --remote --all`.match(/\((.+)\)/)[1].split(', ').each do |version|
      if version.in? except
        puts "skipped version [#{version}]"
      else
        puts `gem yank #{name} -v #{version}`
      end
    end
  end
end

namespace :tmp do
  desc 'truncate log'
  task :truncate_log, [:suffix] => :environment do |t, args|
    if (suffix = args[:suffix]).present?
      sh "truncate -s 0 log/#{Rails.env}.log#{suffix}"
    else
      sh "truncate -s 0 log/#{Rails.env}.log"
    end
  end
end
