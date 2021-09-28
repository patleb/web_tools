class Monit
  def self.capture
    Monits::Linux::Host.capture
    Monits::Postgres::Database.capture
  rescue Exception => exception
    unless exception.is_a? RescueError
      exception = Rescues::MonitError.new(exception)
    end
    Notice.deliver! exception
  end

  def self.cleanup
    Monits::Postgres::Database.cleanup
  end
end
