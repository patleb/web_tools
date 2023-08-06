module ExtRice
  class Compiler < Rake::TaskLib
    def run(numo = true)
      argv_was = ARGV.dup
      ARGV << "--srcdir=#{Rice.dst}"

      lib_path = Rice.root.join('app/libraries')
      bin_path = lib_path.join("ext.#{RbConfig::CONFIG['DLEXT']}")
      tmp_path = Rice.root.join('tmp/rice/lib')

      bin_path.delete(false)
      tmp_path.rmtree(false)
      tmp_path.mkdir_p
      lib_path.mkdir_p

      $numo = numo
      rel_extconf = Rice.extconf.relative_path_from(tmp_path).to_s
      chdir tmp_path do
        load(rel_extconf)
      end

      sh make, chdir: tmp_path

      rel_lib_path = Pathname(lib_path).relative_path_from(tmp_path).to_s
      make_install = [make, 'install', "sitearchdir=#{rel_lib_path}", "sitelibdir=#{rel_lib_path}"]
      sh(*make_install, chdir: tmp_path)
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
