module ExtRake
  module Try
    class SendMail < ActiveTask::Base
      class Message < ::StandardError
        def backtrace
          ['Notification']
        end
      end

      def send_mail
        exception = Message.new
        exception = ::RescueError.new(exception) if defined? ::RescueError
        Notice.new.deliver! exception, subject: self.class.name do |message|
          puts message
        end
      end
    end
  end
end
