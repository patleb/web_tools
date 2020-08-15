module ExtRake
  module Try
    class SendMail < ActiveTask::Base
      class Message < ::StandardError
        def backtrace
          ['Notification']
        end
      end

      def send_mail
        Notice.deliver! Message.new
      end
    end
  end
end
