require 'capybara'
require 'selenium-webdriver'
# TODO require 'chromedriver-helper'

Capybara.server = :webrick
Capybara.app_host = "http://#{Rails.application.config.asset_host}"
url_options = Rails.application.config.action_mailer.default_url_options
Capybara.server_host, Capybara.server_port = url_options.values_at(:host, :port)

ActionDispatch::SystemTestCase.class_eval do
  driven_by :selenium, using: :headless_chrome

  let(:run_timeout){ false }

  before{ WebMock.allow_net_connect! }

  after do
    if (log_lines = page.driver.browser.manage.logs.get(:browser)).present?
      warnings = log_lines.select_map{ |error| error.message if error.level == 'WARNING' }
      errors = log_lines.select_map{ |error| error.message if error.level == 'SEVERE' }
      puts warnings.join.unescape_newlines if warnings.any?
      if errors.any?
        puts errors.join.unescape_newlines
        assert false
      end
    end
  end
end
