require './test/test_helper'

class Process::PassengerTest < ActiveSupport::TestCase
  let(:run_timeout){ 10 }
  let(:passenger){ Process.passenger }

  test '.passenger' do
    pid = spawn 'passenger start -p 3999 -e test --min-instances 1 --max-pool-size 2'
    Thread.pass until passenger.available? timeout: 1
    assert Process::Passenger::SERVER.keys.sort, passenger.server.values
    assert_equal 1, passenger.pool[:group_count].to_i
    assert_retry 2, passenger.pool[:max].to_i do
      passenger.pool(force: true)[:max].to_i
    end
  ensure
    if pid
      Process.kill('TERM', pid)
      Process.detach pid
    end
    Pathname.new('./tmp/pids').glob('passenger.3999.*').each(&:delete.with(false))
  end
end
