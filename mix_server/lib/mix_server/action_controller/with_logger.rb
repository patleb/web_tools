module ActionController::WithLogger
  extend ActiveSupport::Concern

  class_methods do
    def inherited(subclass)
      super
      if subclass.superclass.superclass == ActionController::Metal
        subclass.class_eval do
          private

          def log(exception, subject: nil, **)
            unless exception.is_a? RescueError
              exception = Rescues::RailsError.new(exception, data: Rack::Utils.log_context(request))
            end
            Notice.deliver! exception, subject: subject
          rescue Exception => e
            Log.rescue(e)
          end
        end
      end
    end
  end
end
