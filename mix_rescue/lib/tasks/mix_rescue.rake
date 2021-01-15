module MixRescue
  module Try
    class Message < ::StandardError
      def backtrace
        caller
      end
    end
  end
end

namespace :try do
  desc "try send notice"
  task :send_notice => :environment do
    MixRescue.with do |config|
      config.skip_notice = false
      Notice.deliver! MixRescue::Try::Message.new, data: { text: 'Text' }
    end
  end
end

namespace :throttler do
  desc 'clear all'
  task :clear_all, [:prefix] => :environment do |t, args|
    Throttler.clear(args[:prefix])
  end
end
