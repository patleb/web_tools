module Monit
  def self.capture
    Linux::Host.capture
    Postgres::Database.capture
  end

  def self.cleanup
    Postgres::Database.cleanup
  end
end
