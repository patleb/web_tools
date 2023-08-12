module ExtRice
  class Compiler < Rake::TaskLib
    RICE_TEST_FILES = %w(embed_ruby.cpp embed_ruby.hpp unittest.cpp unittest.hpp)

    def self.make
      @make ||= begin
        paths = ENV["PATH"].split(File::PATH_SEPARATOR).map{ |path| Pathname(path).cleanpath }
        paths.find{ |path| path.join('make').executable? }.join('make').to_s
      end
    end

    delegate :make, to: :class

    def test_compile(root:, scope: ("test/#{root}" if root && !root.to_s.start_with?('/')))
      ExtRice.with do |config|
        config.executable = true
        config.scope = scope
        config.target = 'unittest'
        config.target_path = config.tmp_path
        config.root_app = Pathname.new(root).expand_path.join('test/rice')
        config.extconf_path = config.root_app.join('extconf.rb')
        RICE_TEST_FILES.each do |file|
          cp Gem.root('rice').join('test', file), config.root_app, verbose: false
        end
        run
      end
    end

    def run(compile: true)
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
        if compile && Rice.checksum_changed?
          Rice.bin_path.delete(false)
          sh make
          if Rice.executable?
            bin_path = Rice.mkmf_path.join(Rice.target)
            cp bin_path, Rice.bin_path
          else
            sh make, 'install', "sitearchdir=#{rel_target_path}", "sitelibdir=#{rel_target_path}"
          end
          Rice.write_checksum
        end
      end
    ensure
      ARGV.replace(argv_was)
    end
  end
end
