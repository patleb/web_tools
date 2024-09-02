require './test/test_helper'

class Monit::Postgres::DatabaseTest < ActiveSupport::TestCase
  let(:run_timeout){ 3 }

  test '.capture' do
    Monit::Postgres::Database.capture
    line = LogLines::Database.first
    message = line.log_message
  end
end
