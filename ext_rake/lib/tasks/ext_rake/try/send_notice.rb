module ExtRake
  module Try
    class SendNotice < ActiveTask::Base
      class Message < ::StandardError
        def backtrace
          ['Notification']
        end
      end

      def send_notice
        Notice.deliver! Message.new
      end
    end
  end
end
