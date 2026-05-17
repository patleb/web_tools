module Monit
  def self.capture
    Linux::Host.capture
    Postgres::Database.capture
  rescue Exception => exception
    Log.rescue(exception)
  end

  def self.cleanup
    Postgres::Database.cleanup
  end
end
