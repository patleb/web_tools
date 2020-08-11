require "minitest"
require "rails/test_unit/runner"

module ExtMinitest
  class Runner < Rails::TestUnit::Runner
    def self.testable_gems
      @testable_gems ||= WebTools.gems.select{ |_name, path| path.join('test').exist? }
    end

    def self.test_all(name = nil)
      if name.present?
        rake_run([testable_gems[name].join('test').to_s])
      else
        rake_run(['test'].concat(testable_gems.values.map(&:join.with('test')).map(&:to_s)))
      end
    end

    def self.rake_run(argv = [])
      $: << "test"
      super
    end
  end
end
