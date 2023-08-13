module Rice
  class TestCase < Minitest::Spec
    let(:run_timeout){ false }

    def self.test_cpp(rel_root = nil)
      it "should execute c++ tests for suite: #{scope rel_root}" do
        assert_equal true, system("bin/rake rice:test_compile[#{rel_root}]")
        assert_equal true, system(Pathname.new('tmp/rice/test').join(rel_root, 'unittest').to_s)
      end
    end

    def self.test_yml(rel_root = nil, fixture_yml: false)
      fixtures = fixtures_root(rel_root)

      it "should compile ext.cpp correctly based on rice.yml:  #{scope rel_root}" do
        dst_path = Bundler.root.join('tmp/rice/test', rel_root, 'test')
        root = rel_root ? Pathname.new(rel_root).expand_path : Bundler.root

        ExtRice.with do |config|
          config.yml_path = fixture_yml ? fixtures.join('rice.yml') : root.join('config/rice.yml')
          config.dst_path = dst_path
          Rice.create_makefile(numo: false, dry_run: true)
        end

        assert_equal fixtures.join('ext.cpp').read, dst_path.join('ext.cpp').read
      end
    end

    def self.scope(rel_root)
      rel_root ? File.basename(Dir.pwd) : rel_root
    end

    def self.fixtures_root(rel_root)
      (rel_root ? Pathname.new(rel_root) : Bundler.root).join('test/fixtures/files').expand_path
    end
  end
end
