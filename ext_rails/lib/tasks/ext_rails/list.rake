namespace :list do
  desc 'reorganize lists'
  task :reorganize => :environment do |t|
    Rails.application.eager_load!
    ActiveRecord::Base.listables.each(&:list_reorganize)
  end
end
