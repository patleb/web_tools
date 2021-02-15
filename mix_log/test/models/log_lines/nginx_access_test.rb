require './test/rails_helper'
require Gem.root('mix_log').join('test/fixtures/files/log/nginx/web_tools.access.rb').to_s

module LogLines
  class NginxAccessTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/nginx/web_tools.access.log.0')

      log = Log.create! server: Server.current, path: file.to_s.delete_suffix('.0')
      file.each_line.with_index do |line, i|
        assert_equal ACCESS_EXPECTATIONS[i], LogLines::NginxAccess.parse(log, line, mtime: file.mtime)
      end
    end

    it 'should fetch results' do
      MixLog.with do |config|
        log_path = config.log_path(:nginx, 'web_tools.access')
        config.available_paths = [log_path]
        Rake::Task['log:extract'].invoke
        assert_equal Time.new(2021, 1, 19, 15, 3, 37, 0), LogLines::NginxAccess.requests_begin_at
        assert_equal Time.new(2021, 2, 2, 22, 15, 13, 0), LogLines::NginxAccess.requests_end_at
        assert_equal 6,     LogLines::NginxAccess.total_requests.values.sum
        assert_equal 0.029, LogLines::NginxAccess.total_mbytes_out
        assert_equal 3,     LogLines::NginxAccess.total_referers.values.sum
        assert_equal 9,     LogLines::NginxAccess.unique_users.count
        assert_equal 2,     LogLines::NginxAccess.average_users
        assert_equal 0.01,  LogLines::NginxAccess.average_mbytes_out
        assert_equal 0.079, LogLines::NginxAccess.average_time
        assert_equal 4,     LogLines::NginxAccess.users_by(:week).values.sum
        assert_equal 0.029, LogLines::NginxAccess.mbytes_out_by(:browser).values.sum.ceil(3)
        assert_equal 0.236, LogLines::NginxAccess.time_by(:platform).values.sum.ceil(3)
        assert_equal 14,    LogLines::NginxAccess.requests_by(:status).values.sum

        Rake::Task['log:rollup'].invoke!
        assert_equal 3, weeks

        period_at = LogRollups::NginxAccess.order(period: :desc, period_at: :desc).pick(:period_at)
        LogRollups::NginxAccess.where('period_at >= ?', period_at).delete_all

        assert_equal 2, weeks
        Rake::Task['log:rollup'].invoke
        assert_equal 3, weeks
      end
    end

    private

    def weeks
      LogRollups::NginxAccess.where(group_name: :period, period: 1.week).count
    end
  end
end
