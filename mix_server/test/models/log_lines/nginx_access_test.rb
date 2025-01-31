require './test/test_helper'
require Gem.root('mix_server').join('test/fixtures/files/log/nginx/test_web_tools.access.rb').to_s

module LogLines
  class NginxAccessTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s
    self.use_transactional_tests = false

    test '.parse' do
      file = file_fixture('log/nginx/test_web_tools.access.log.0')

      log = Log.create! server: Server.current, path: file.to_s.delete_suffix('.0')
      file.each_line.with_index do |line, i|
        assert_equal ACCESS_EXPECTATIONS[i], LogLines::NginxAccess.parse(log, line, mtime: file.mtime)
      end
    end

    test 'scopes' do
      MixServer::Logs.with do |config|
        log_path = config.log_path(:nginx, 'test_web_tools.access')
        config.available_paths = [log_path]
        Rake::Task['log:extract'].invoke!
        assert_equal Time.utc(2021, 1, 19, 15, 3, 37, 0), LogLines::NginxAccess.requests_begin_at
        assert_equal Time.utc(2021, 2, 2, 22, 15, 13, 0), LogLines::NginxAccess.requests_end_at
        assert_equal 6,     LogLines::NginxAccess.total_requests.values.sum
        assert_equal 29626, LogLines::NginxAccess.total_bytes_out
        assert_equal 3,     LogLines::NginxAccess.total_referers.values.sum
        assert_equal 9,     LogLines::NginxAccess.unique_users.count
        assert_equal 2,     LogLines::NginxAccess.average_users
        assert_equal 9876,  LogLines::NginxAccess.average_bytes_out
        assert_equal 0.079, LogLines::NginxAccess.average_time
        assert_equal 4,     LogLines::NginxAccess.users_by(:week).values.sum
        assert_equal 29626, LogLines::NginxAccess.bytes_out_by(:browser).values.sum
        assert_equal 0.237, LogLines::NginxAccess.time_by(:platform).values.sum
        assert_equal 14,    LogLines::NginxAccess.requests_by(:status).values.sum

        Rake::Task['log:rollup'].invoke!
        assert_equal 3, rollup_weeks

        period_at = LogRollups::NginxAccess.order(period: :desc, period_at: :desc).pick(:period_at)
        LogRollups::NginxAccess.where('period_at >= ?', period_at).delete_all

        assert_equal 2, rollup_weeks
        Rake::Task['log:rollup'].invoke
        assert_equal 3, rollup_weeks

        assert_equal Time.utc(2021, 1, 19), LogRollups::NginxAccess.requests_begin_at
        assert_equal Time.utc(2021, 2, 2), LogRollups::NginxAccess.requests_end_at
        assert_equal 6,         LogRollups::NginxAccess.total_requests
        assert_equal '28,9 ko', LogRollups::NginxAccess.total_bytes_out
        assert_equal 0.079,     LogRollups::NginxAccess.average_time
        assert_equal({ '2021-01-01'=> 5, '2021-02-01'=> 1 },                    LogRollups::NginxAccess.requests_by(:month).to_h)
        assert_equal({ '2021-01-19'=> 4, '2021-01-26'=> 1, '2021-02-02'=> 1 },  LogRollups::NginxAccess.requests_by(:day).to_h)
        assert_equal({ '200'=> 6, '301'=> 1, '302'=> 1, '304'=> 2, '444'=> 4 }, LogRollups::NginxAccess.requests_by(:status).to_h)
        assert_equal({ '2021-01-18'=> 2, '2021-01-25'=> 1, '2021-02-01'=> 1 },  LogRollups::NginxAccess.users_by.to_h)
      end
    end

    private

    def rollup_weeks
      LogRollups::NginxAccess.where(group_name: :period, period: 1.week).count
    end
  end
end
