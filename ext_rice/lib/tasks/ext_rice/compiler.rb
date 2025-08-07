module ExtRice
  class Compiler < Rake::TaskLib
    RICE_TEST_FILES = %w(embed_ruby.cpp embed_ruby.hpp unittest.cpp unittest.hpp)

    def self.make
      @make ||= Pathname.executable('make').to_s
    end

    delegate :make, to: :class

    def test_suite(root: nil)
      ExtRice.with do |config|
        config.executable = true
        configure_test(config, root, target: 'unittest')
        RICE_TEST_FILES.each do |file|
          cp Gem.root('rice').join('test', file), config.root_test, verbose: false
        end
        run
        RICE_TEST_FILES.each do |file|
          config.root_test.join(file).delete(false)
        end
      end
    end

    def test_extension(root: nil)
      ExtRice.with do |config|
        configure_test(config, root)
        run
      end
    end

    def run(compile: true, jobs: cpu_count)
      argv_was = ARGV.dup
      ARGV << "--srcdir=#{Rice.dst_path}"

      target_path = Rice.target_path
      mkmf_path = Rice.mkmf_path

      mkmf_path.rmtree(false)
      mkmf_path.mkdir_p
      target_path.mkdir_p

      rel_extconf = Rice.extconf_path.relative_path_from(mkmf_path).to_s
      rel_target_path = Pathname(target_path).relative_path_from(mkmf_path).to_s
      chdir mkmf_path, verbose: false do
        load(rel_extconf)
        next unless compile
        next unless Rice.checksum_changed? || !Rice.bin_path.exist?
        Rice.bin_path.delete(false)
        sh make, '-j', jobs.to_s
        if Rice.executable?
          bin_path = Rice.mkmf_path.join(Rice.target)
          cp bin_path, Rice.bin_path
        else
          sh make, '-j', jobs.to_s, 'install', "sitearchdir=#{rel_target_path}", "sitelibdir=#{rel_target_path}"
        end
        Rice.write_checksum
      end
    ensure
      ARGV.replace(argv_was)
    end

    private

    def configure_test(config, root, target: nil)
      if root.present?
        config.root = Pathname.new(root).expand_path
        config.root_app = config.root.join('lib/rice')
        config.extconf_path = config.root_test.join('extconf.rb')
      end
      config.target = target if target
      config.target_path = config.tmp_path
    end

    def cpu_count
      count  = Process.host.cpu_count
      count -= 2 unless Rails.env.local? || ENV['JOBS']&.downcase == 'all'
      count  = 1 if count <= 0
      count
    end
  end
end
