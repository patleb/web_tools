require 'ext_coffee'
require 'ext_css'
# require 'ext_minitest'
require 'ext_rails'
require 'ext_rice'
require 'ext_ruby'
# require 'ext_shakapacker'
# require 'ext_whenever'
require 'mix_admin'
require 'mix_certificate'
require 'mix_file'
require 'mix_flash'
require 'mix_geo'
require 'mix_global'
require 'mix_job'
require 'mix_page'
require 'mix_rpc'
require 'mix_search'
require 'mix_server'
require 'mix_setting'
require 'mix_task'
require 'mix_user'
require 'sunzistrano'

module WebTools
  def self.isolated_test_gems
    ['ext_rice', 'mix_geo', 'mix_task']
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__))
  end

  module self::WithTestTasks
    def gems
      @gems ||= subgems(root).index_with{ |d| Gem.root(d) }.to_hwia
    end

    def subgems(root)
      list = root.children.select do |d|
        d.directory? && d.children.any?{ |f| f.to_s.end_with? '.gemspec' }
      end
      list.any? ? list.map{ |d| d.basename.to_s } : [root.basename.to_s]
    end

    def define_test_tasks(rake)
      rake.send :namespace, :test do
        testable_gems = gems.select{ |_name, path| path.join('test').exist? }
        minitest_gems = testable_gems.select{ |_name, path| path.glob('test/**/*_test.rb').first.read.include? 'test/spec_helper' }

        rake.send :desc, "run all tests for #{name}"
        rake.send :task, :"#{name.full_underscore}" do
          isolated_test_gems = try(:isolated_test_gems) || []
          isolated_tests = testable_gems.each_with_object([{}, {}]) do |(name, path), memo|
            path = path.join('test').to_s
            if isolated_test_gems.include? name.to_s
              memo.unshift(name => path)
            elsif minitest_gems.has_key? name.to_s
              memo[-2][name] = path
            else
              memo[-1][name] = path
            end
          end
          isolated_tests.compact_blank.each do |gems|
            puts "run all tests for: #{gems.keys.map(&:camelize).sort.join(', ')}"
            Rails::TestUnit::Runner.run_from_rake 'test', gems.values
          end
        end

        testable_gems.each_key do |name|
          rake.send :desc, "run all tests for #{name.camelize}"
          rake.send :task, name do
            Rails::TestUnit::Runner.run_from_rake 'test', testable_gems[name].join('test').to_s
          end
        end
      end
    end
  end
  extend self::WithTestTasks
end
