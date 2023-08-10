module ExtRice
  class Compiler < Rake::TaskLib
    def run(compile: true)
      argv_was = ARGV.dup
      ARGV << "--srcdir=#{Rice.dst}"

      lib_path = Rice.lib_path
      tmp_path = Rice.tmp_path.join('lib')

      tmp_path.rmtree(false)
      tmp_path.mkdir_p
      lib_path.mkdir_p

      rel_extconf = Rice.extconf.relative_path_from(tmp_path).to_s
      rel_lib_path = Pathname(lib_path).relative_path_from(tmp_path).to_s
      chdir tmp_path do
        load(rel_extconf)
        if compile &&= Rice.checksum_changed?
          Rice.write_checksum
          Rice.bin_path.delete(false)
          sh make
          sh make, 'install', "sitearchdir=#{rel_lib_path}", "sitelibdir=#{rel_lib_path}"
        end
      end
    ensure
      ARGV.replace(argv_was)
    end

    private

    def make
      @make ||= find_make
    end

    ### References
    # rake-compiler
    def find_make
      candidates = ["gmake", "make"]
      paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
      paths = paths.collect do |path|
        Pathname(path).cleanpath
      end
      exeext = RbConfig::CONFIG["EXEEXT"]
      candidates.each do |candidate|
        paths.each do |path|
          make = path + "#{candidate}#{exeext}"
          return make.to_s if make.executable?
        end
      end
      nil
    end
  end
end
