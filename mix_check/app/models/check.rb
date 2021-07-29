class Check
  def self.capture
    Checks::Linux::Host.capture
    Checks::Postgres::Database.capture
  end

  def self.cleanup
    Checks::Postgres::Database.cleanup
  end
end
