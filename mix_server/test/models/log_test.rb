require './test/test_helper'

class LogTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActionMailer::TestCase::ClearTestDeliveries

  self.use_transactional_tests = false

  test '.fs_type' do
    { 'log/test.log'                                                   => 'LogLines::App',
      '/log/apt/history.log'                                           => 'LogLines::AptHistory',
      '/files/log/syslog'                                              => 'LogLines::Syslog',
      '/fixtures/files/log/nginx/web_tools_test.access.log'            => 'LogLines::NginxAccess',
      'test/fixtures/files/log/nginx/web_tools_test_packs.access.log'  => 'LogLines::NginxAccess',
      'test/fixtures/files/log/nginx/web_tools_test_public.access.log' => 'LogLines::NginxAccess',
      'test/fixtures/files/log/nginx/error.log'                        => 'LogLines::NginxError',
      'test/fixtures/files/log/auth.log'                               => 'LogLines::Auth',
      'test/fixtures/files/log/postgresql/postgresql-14-main.log'      => 'LogLines::Postgresql',
      '/var/log/osquery/osqueryd.results.log'                          => 'LogLines::Osquery',
    }.each do |path, model|
      assert_equal model, Log.fs_type(path)
    end
  end

  test '.rescue, .rescue_not_reportable, .report!' do
    Log.rescue StandardError.new('error')
    message = LogMessage.where('text_tiny LIKE ?', '%error%').take
    assert_match /^error$/, message.text
    assert_equal nil, message.monitor
    assert_equal 1, message.log_lines_count

    Log.rescue_not_reportable StandardError.new('error')
    assert_equal false, message.reload.monitor
    assert_equal 2, message.log_lines_count

    Log.rescue_not_reportable StandardError.new('error 2')
    message = LogMessage.where('text_tiny LIKE ?', '%error *%').take
    assert_equal 1, message.log_lines_count
    assert_match /^error 2$/, message.text
    assert_equal false, message.monitor

    Log.rescue StandardError.new('error 3')
    assert_equal 2, message.reload.log_lines_count
    assert_match /^error 2$/, message.text
    assert_equal nil, message.monitor

    Log.rescue StandardError.new('error not a number')
    log = Log.where(log_lines_type: 'LogLines::Rescue').take
    assert_equal '', log.path
    assert_equal 5, log.log_lines_count
    assert_equal 3, log.log_messages.size
    assert_equal Server.current, log.server

    log = Log.create! server: Server.current, path: 'log/nginx/web_tools.access.log'
    assert_equal({ created_at: nil, filtered: true }, LogLines::NginxAccess.parse(log, 'invalid'))
    assert_equal 'invalid', LogUnknown.where(text_hash: 'invalid'.squish_all(256)).pluck(:text).first

    assert_equal({ error: [
      'Rescue => [RescueError] [RESCUE][StandardError] error not a number {}',
      'Rescue => [RescueError] [RESCUE][StandardError] error * {}',
    ]}, LogMessage.report.first.last)
    assert_equal 1, LogUnknown.report
    assert_emails 1 do
      Log.report!
    end
  end
end
