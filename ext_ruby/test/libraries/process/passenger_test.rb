require './test/test_helper'

class Process::PassengerTest < Minitest::TestCase
  let(:run_timeout){ 10 }
  let(:passenger){ Process.passenger }

  test '.passenger' do
    pid = spawn 'passenger start -p 3999 -e test --min-instances 1 --max-pool-size 2'
    Thread.pass until passenger.available? timeout: 1
    assert Process::Passenger::SERVER.keys.sort, passenger.server.values
    assert_equal 1, passenger.pool[:group_count].to_i
    assert_equal 2, passenger.pool[:max].to_i
  ensure
    if pid
      Process.kill('TERM', pid)
      Process.detach pid
    end
  end
end
