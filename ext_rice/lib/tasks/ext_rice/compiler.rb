module ExtRice
  class Compiler < Rake::TaskLib
    def self.make
      @make ||= Pathname.executable('make').to_s
    end

    delegate :make, to: :class

    def run(compile: true, jobs: cpu_count)
      argv_was = ARGV.dup
      ARGV << "--srcdir=#{Rice.dst_path}"

      mkmf_path = Rice.mkmf_path
      app_path = Rice.app_path

      mkmf_path.rmtree(false)
      mkmf_path.mkdir_p
      app_path.mkdir_p

      chdir mkmf_path, verbose: false do
        load Rice.extconf_path.expand_path.to_s
        next unless compile
        next unless Rice.checksum_changed? || !Rice.bin_path.exist?
        Rice.bin_path.delete(false)
        sh make, '-j', jobs.to_s
        if Rice.executable?
          bin_path = Rice.mkmf_path.join(Rice.target)
          cp bin_path, Rice.bin_path
        else
          sh make, '-j', jobs.to_s, 'install', "sitearchdir=#{app_path}", "sitelibdir=#{app_path}"
        end
        Rice.write_checksum
      end
    ensure
      ARGV.replace(argv_was)
    end

    private

    def cpu_count
      count  = Process.host.cpu_count
      count -= 2 unless Rails.env.local? || ENV['JOBS']&.downcase == 'all'
      count  = 1 if count <= 0
      count
    end
  end
end
