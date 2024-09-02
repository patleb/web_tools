class Db::Pg::TestCase < Rake::TestCase
  def version
    @version ||= `git rev-parse --short HEAD`.strip.first(7)
  end

  def today
    @today ||= Time.today.date_tag
  end
end
