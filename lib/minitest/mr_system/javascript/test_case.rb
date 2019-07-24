module Javascript
  class TestCase < ActionDispatch::SystemTestCase
    FAILURES = '#teaspoon-report-failures > li'.freeze

    def take_failed_screenshot
      false
    end

    def self.test_javascript(suite_name = 'default', **)
      it "should run javascript for suite: #{suite_name.full_underscore}" do
        visit teaspoon_path
        click_link suite_name
        refute page.has_css?(FAILURES), page.all(FAILURES).map(&:text).join("\n")
      end
    end
  end
end
