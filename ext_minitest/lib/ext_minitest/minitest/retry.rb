### References
# https://github.com/appfolio/minitest-optional_retry
module Minitest
  module Retry
    def run_one_method(klass, method_name, reporter)
      report_result = nil
      2.times do
        result = Minitest.run_one_method(klass, method_name)
        report_result ||= result
        (report_result = result) and break if result.passed?
      end
      reporter.record(report_result)
    end
  end
end
