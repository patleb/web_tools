require './test/test_helper'

class Process::PassengerTest < ActiveSupport::TestCase
  let(:run_timeout){ 10 }
  let(:passenger){ Process.passenger }

  if ENV['CI'].present?
    test '.passenger' do
      Thread.pass until passenger.available? timeout: 1
      assert Process::Passenger::SERVER.keys.sort, passenger.server.values
      assert passenger.pool[:group_count].to_i > 0
      assert passenger.pool[:max].to_i > 1
    end
  else
    xtest '.passenger' do
      # do nothing
    end
  end
end
