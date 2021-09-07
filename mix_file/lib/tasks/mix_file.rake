namespace :file do
  desc 'restore files'
  task :restore_all => :environment do
    ActiveStorage::Blob.find_each(&:restore_file)
  end
end
