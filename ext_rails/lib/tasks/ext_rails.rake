namespace :list do
  desc 'reorganize lists'
  task :reorganize => :environment do |t|
    Rails.application.eager_load!
    ActiveRecord::Base.listables.each(&:list_reorganize)
  end
end

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
