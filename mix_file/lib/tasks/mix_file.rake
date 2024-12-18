namespace :file do
  desc 'restore files'
  task :restore_all => :environment do
    ActiveStorage::Blob.find_in_batches do |batch|
      Parallel.each(batch) do |blob|
        blob.restore_file
      end
    end
  end

  desc 'cleanup unattached blobs'
  task :cleanup => :environment do
    ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge)
  end
end
