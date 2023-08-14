module Rice
  class TestCase < Minitest::Spec
    let(:run_timeout){ false }

    def self.test_ext(rel_root = nil, &block)
      bin_path = Pathname.new('tmp/rice/test').join(root_name(rel_root), 'ext.so').expand_path

      it "should execute c++ test extension: #{root_name rel_root}" do
        assert_equal true, system("bin/rake rice:test_extension[#{rel_root}]")
        assert_equal true, bin_path.exist?
        require bin_path
        instance_eval(&block)
      end
    end

    def self.test_cpp(rel_root = nil)
      bin_path = Pathname.new('tmp/rice/test').join(root_name(rel_root), 'unittest')

      it "should execute c++ test suite: #{root_name rel_root}" do
        assert_equal true, system("bin/rake rice:test_suite[#{rel_root}]")
        assert_equal true, bin_path.exist?
        assert_equal true, system(bin_path.to_s)
      end
    end

    def self.test_yml(rel_root = nil, yml_path: nil)
      it "should build ext.cpp correctly based on rice.yml:  #{root_name rel_root}" do
        ExtRice.with do |config|
          config.root = Pathname.new(rel_root).expand_path if rel_root
          config.yml_path = yml_path if yml_path
          config.dst_path = config.dst_path.dirname.join('yml')
          Rice.create_makefile(numo: false, dry_run: true)

          assert_equal file_fixture_path(rel_root).join('ext.cpp').read, config.dst_path.join('ext.cpp').read
        end
      end
    end

    def self.root_name(rel_root)
      raise "invalid relative root: #{rel_root}" if rel_root.start_with?('/') || !Dir.exist?(rel_root)
      File.basename(rel_root || Bundler.root)
    end

    def self.file_fixture_path(rel_root)
      (rel_root ? Pathname.new(rel_root) : Bundler.root).join('test/fixtures/files').expand_path
    end

    delegate :file_fixture_path, to: :class
  end
end
