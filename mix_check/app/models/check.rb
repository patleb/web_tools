class Check
  def self.capture
    Checks::Linux::Host.capture
    Checks::Postgres::Database.capture
  rescue Exception => exception
    unless exception.is_a? RescueError
      exception = Rescues::CheckError.new(exception)
    end
    Notice.deliver! exception
  end

  def self.cleanup
    Checks::Postgres::Database.cleanup
  end
end
