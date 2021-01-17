require './test/rails_helper'

module MixLog
  class ExtractTest < Rake::TestCase
    it 'should extract syslog files' do
      MixLog.with do |config|
        log_path, log_time = config.log_path(:syslog), Time.new(2021, 1, 2, 0, 0, 0, 0)
        config.available_paths = [log_path]
        FileUtils.touch log_path, mtime: log_time
        FileUtils.touch "#{log_path}.1", mtime: log_time - 1.day

        run_task parallel: false
        timestamps = LogLine.all.map(&:created_at)
        assert_equal 2, LogLabel.count
        assert_equal [2021, 2021], timestamps.map(&:year)
        assert_equal [0, 1], timestamps.map(&:strftime.with('%6N')).map(&:to_i)

        run_task parallel: false
        assert_equal 2, LogLine.count

        log = Log.first
        log.update! last_line_i: 1, last_line_at: log_time - 1.second

        run_task parallel: false, current: true
        log.reload
        timestamps = LogLine.order(:created_at).map(&:created_at)
        assert_equal 3, LogLabel.count
        assert_equal [2020, 2021, 2021, 2021], timestamps.map(&:year)
        assert_equal log_time, log.last_line_at
        assert_equal 4, log.last_line_i

        run_task parallel: false, current: true
        assert_equal 4, LogLine.count
      end
    end
  end
end
