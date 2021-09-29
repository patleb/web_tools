module Monit
  def self.capture
    Linux::Host.capture
    Postgres::Database.capture
  rescue Exception => exception
    unless exception.is_a? RescueError
      exception = Rescues::MonitError.new(exception)
    end
    Notice.deliver! exception
  end

  def self.cleanup
    Postgres::Database.cleanup
  end
end
