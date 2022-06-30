module Log::WithRescue
  extend ActiveSupport::Concern

  class_methods do
    def rescue_not_reportable(exception, data: nil)
      db_log('LogLines::Rescue').push(exception, data: data, monitor: false)
    end
  end
end
