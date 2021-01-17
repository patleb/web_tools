require './test/rails_helper'

module MixLog
  class ExtractTest < Rake::TestCase
    it 'should extract syslog files' do
      MixLog.with do |config|
        log_path, log_time = config.log_path(:syslog), Time.new(2021, 1, 2, 0, 0, 0, 0)
        config.available_paths = [log_path]
        FileUtils.touch log_path, mtime: log_time
        FileUtils.touch "#{log_path}.1", mtime: log_time - 1.day

        run_task
        timestamps = LogLine.all.map(&:created_at)
        assert_equal 2, LogLabel.count
        assert_equal [2021, 2021], timestamps.map(&:year)
        assert_equal [0, 1], timestamps.map(&:strftime.with('%6N')).map(&:to_i)

        ensure_rotate = rotate_files(log_path)

        run_task
        timestamps = LogLine.order(:created_at).map(&:created_at)
        assert_equal 3, LogLabel.count
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
