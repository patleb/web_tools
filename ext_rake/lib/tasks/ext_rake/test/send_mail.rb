module ExtRake
  module Test
    class SendMail < ActiveTask::Base
      class Message < ::StandardError
        def backtrace
          ['Notification']
        end
      end

      def send_mail
        exception = Message.new
        exception = ::RescueError.new(exception) if Gem.loaded_specs['mix_rescue']
        Notice.new.deliver! exception, subject: self.class.name do |message|
          puts message
        end
      end
    end
  end
end
