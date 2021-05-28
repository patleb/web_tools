module MixLog
  class Report < ActiveTask::Base
    def self.args
      { all: ['--[no-]all', 'Report all errors since the beginning'] }
    end

    def report
      since = 1.day.ago unless options.all
      if LogMessage.report? since
        LogMailer.report(since).deliver_now
        LogMessage.reported! since
      end
    end
  end
end
