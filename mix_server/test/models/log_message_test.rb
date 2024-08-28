require './test/test_helper'

class LogMessageTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActionMailer::TestCase::ClearTestDeliveries

  self.use_transactional_tests = false

  test '.report!' do
    Log.rescue StandardError.new('error')
    Log.rescue_not_reportable StandardError.new('error 2')
    Log.rescue_not_reportable StandardError.new('error text')
    Log.rescue StandardError.new('error')
    Log.rescue StandardError.new('error 3') # same :text_tiny as 'error 2'
    Log.rescue StandardError.new('error not a number')
    assert_equal({ error: [
      'Rescue => [RescueError] [RESCUE][StandardError] error not a number {}',
      'Rescue => [RescueError] [RESCUE][StandardError] error * {}',
      'Rescue => [RescueError] [RESCUE][StandardError] error {}',
    ]}, LogMessage.report.first.last)
    assert_emails 1 do
      LogMessage.report!
    end
  end
end
