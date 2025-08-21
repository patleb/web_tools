module Rice
  class TestCase < ActiveSupport::TestCase
    let(:run_timeout){ false }
    let(:run_debug){ false }

    def run(...)
      begin
        old_env = ENV['RAILS_ENV']
        ENV['RAILS_ENV'] = 'development'
        ENV['DEBUG'] = 'true' if run_debug
        raise 'rice:compile error' unless ($rice_compiled ||= system('rake rice:compile'))
        Rice.require_ext
      ensure
        ENV['RAILS_ENV'] = old_env
      end
      super
    end
  end
end
