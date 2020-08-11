require 'minitest-spec-rails'

module ExtMinitest
  class Railtie < Rails::Railtie
    if ENV['RAILS_ENV'] == 'test'
      initializer 'ext_minitest.mini_shoulda', before: 'minitest-spec-rails.mini_shoulda' do |app|
        app.config.minitest_spec_rails.mini_shoulda = true
      end
    end

    rake_tasks do
      load 'tasks/ext_minitest.rake'
    end
  end
end
