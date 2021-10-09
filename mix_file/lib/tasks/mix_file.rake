namespace :file do
  desc 'restore files'
  task :restore_all => :environment do
    ActiveStorage::Blob.find_in_batches do |batch|
      Parallel.each(batch) do |blob|
        blob.restore_file
      end
    end
  end
end
