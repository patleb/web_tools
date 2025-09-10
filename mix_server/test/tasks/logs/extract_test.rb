require './test/test_helper'

module MixServer::Logs
  class ExtractTest < Rake::TestCase
    self.task_name = 'log:extract'
    self.use_transactional_tests = false

    test 'log:extract' do
      MixServer::Logs.with do |config|
        log_path, log_time = config.log_path(:syslog), Time.utc(2021, 1, 2, 0, 0, 0, 0)
        config.available_paths = [log_path]
        FileUtils.touch log_path, mtime: log_time
        FileUtils.touch "#{log_path}.1", mtime: log_time - 1.day

        run_rake
        timestamps = LogLine.all.map(&:created_at)
        assert_equal 2, LogMessage.count
        assert_equal [2021, 2021], timestamps.map(&:year)
        assert_equal [0, 1], timestamps.map(&:strftime.with('%6N')).map(&:to_i)

        ensure_rotate = rotate_files(log_path)
        log = Log.first
        log.update! line_i: 1

        run_rake
        timestamps = LogLine.order(:created_at).map(&:created_at)
        assert_equal 3, LogMessage.count
        assert_equal [2020, 2021, 2021, 2021], timestamps.map(&:year)
        assert_equal log_time, Log.first.mtime
      ensure
        reset_files(log_path) if ensure_rotate
      end
    end

    private

    def rotate_files(log_path)
      File.rename "#{log_path}.1", "#{log_path}.2"
      File.rename log_path, "#{log_path}.1"
    end

    def reset_files(log_path)
      File.rename "#{log_path}.1", log_path
      File.rename "#{log_path}.2", "#{log_path}.1"
    end
  end
end
