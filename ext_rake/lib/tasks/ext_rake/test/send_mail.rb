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
        exception = Message.new
        exception = ::RescueError.new(exception) if Gem.loaded_specs['mr_rescue']
        Notice.new.deliver! exception, subject: self.class.name do |message|
          puts message
        end
      end
    end
  end
end
