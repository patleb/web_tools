module Rice
  class TestCase < Minitest::Spec
    let(:run_timeout){ false }

    cattr_accessor :root_name, :rel_root

    def self.root_name_for(rel_root)
      raise "invalid relative root: #{rel_root}" if rel_root.start_with?('/') || !Dir.exist?(rel_root)
      self.rel_root = rel_root
      self.root_name = File.basename(rel_root || Bundler.root)
    end

    def file_fixture_path
      (rel_root ? Pathname.new(rel_root) : Bundler.root).join('test/fixtures/files').expand_path
    end

    def tmp_path
      scope = rel_root ? root_name : ''
      Pathname.new('tmp/rice/test').join(scope).expand_path
    end

    def self.xtest_ext(...)
    end

    def self.xtest_cpp(...)
    end

    def self.xtest_yml(...)
    end

    def self.test_ext(rel_root = nil, &block)
      it "should execute c++ test extension: #{root_name_for rel_root}" do
        bin_path = tmp_path.join('ext.so')

        assert_equal true, system("bin/rake rice:test_extension[#{rel_root}]")
        assert_equal true, bin_path.exist?
        require bin_path
        instance_eval(&block)
      end
    end

    def self.test_cpp(rel_root = nil)
      it "should execute c++ test suite: #{root_name_for rel_root}" do
        bin_path = tmp_path.join('unittest')

        assert_equal true, system("bin/rake rice:test_suite[#{rel_root}]")
        assert_equal true, bin_path.exist?
        assert_equal true, system(bin_path.to_s)
      end
    end

    def self.test_yml(rel_root = nil, yml_path: nil)
      it "should build ext.cpp correctly based on rice.yml:  #{root_name_for rel_root}" do
        ExtRice.with do |config|
          config.root = Pathname.new(rel_root).expand_path if rel_root
          config.yml_path = yml_path if yml_path
          config.dst_path = config.dst_path.dirname.join('yml')
          Rice.create_makefile(numo: false, dry_run: true)

          assert_equal file_fixture_path.join('ext.cpp').read, config.dst_path.join('ext.cpp').read
        end
      end
    end
  end
end
