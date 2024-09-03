require './test/test_helper'

class MonitTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  let(:run_timeout){ 3 }

  test '.capture' do
    Monit.capture
    host = LogLines::Host.first
    assert_equal MixServer.current_version, host.version
    assert_equal Process.host.private_ip, host.log_message.text
    assert_equal :info, host.log_message.level
    db = LogLines::Database.first
    assert_equal 'test_web_tools', db.name
    assert_equal 'test_web_tools', db.log_message.text
    assert_equal :info, db.log_message.level
    Monit.cleanup
  end
end
