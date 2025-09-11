require_dir __FILE__, 'mix_job'

namespace :job do
  desc '-- [options] Watch jobs and send to workers if ready'
  task :watch => :environment do |t|
    MixJob::Watch.new(self, t).run!
  end

  desc 'inspect current job watcher state'
  task :inspect => :environment do
    pid = Process::Worker.all.find{ |w| w.name == 'ruby' && w.cmdline.include?('bin/rake job:watch') }.pid
    Process.kill 'USR1', pid
  end
end
