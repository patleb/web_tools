require './test/test_helper'

module MixServer::Logs
  class CleanupTest < Rake::TestCase
    self.task_name = 'log:cleanup'
    self.use_transactional_tests = false

    test 'log:cleanup' do
      LogLine._drop_all_partitions!
      LogLine.create_all_partitions(weeks)
      assert_equal past_partitions, LogLine.partitions
      run_rake
      assert_equal current_partitions, LogLine.partitions
    end

    private

    def weeks
      (1...56).each_with_object([14.months.ago.beginning_of_week]){ |_, weeks| weeks << (weeks.last + 1.week) }
    end

    def past_partitions
      weeks.map do |week|
        "lib_log_lines_#{week.date_tag}"
      end
    end

    def current_partitions
      weeks.select{ |week| week >= 1.year.ago.beginning_of_week }.map do |week|
        "lib_log_lines_#{week.date_tag}"
      end
    end
  end
end
