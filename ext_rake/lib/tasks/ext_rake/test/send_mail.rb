module ExtRake
  module Test
    class SendMail < ActiveTask::Base
      class Message < ::StandardError
        def backtrace
          ['Notification']
        end
      end

      def self.steps
        [:send_mail]
      end

      def send_mail
        Notice.new.deliver! Message.new, subject: self.class.name do |message|
          puts message
        end
      end
    end
  end
end
