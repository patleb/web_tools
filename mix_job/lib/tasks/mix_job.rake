require_rel 'mix_job'

namespace :job do
  desc '-- [options] Watch jobs and send to workers if ready'
  task :watch => :environment do |t|
    MixJob::Watch.new(self, t).run!
  end
end
