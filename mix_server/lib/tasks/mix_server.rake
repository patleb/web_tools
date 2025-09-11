require_dir __FILE__, 'mix_server'

module Try
  class Message < ::StandardError
    def backtrace
      caller
    end
  end
end

namespace :try do
  desc "try send notice"
  task :send_notice => :environment do
    MixServer.with do |config|
      config.skip_notice = false
      Notice.deliver! Try::Message.new, data: { text: 'Text' }
    end
  end
end

namespace :throttler do
  desc 'clear all'
  task :clear_all, [:prefix] => :environment do |t, args|
    Throttler.clear(args[:prefix])
  end
end
