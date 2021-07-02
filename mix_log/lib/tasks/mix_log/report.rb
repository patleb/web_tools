module MixLog
  class Report < ActiveTask::Base
    def self.args
      { all: ['--[no-]all', 'Report all errors since the beginning'] }
    end

    def report
      since = 1.day.ago unless options.all
      LogMessage.report! since
    end
  end
end
