module Rice
  module WithPaths
    def log_path
      Pathname.shared_path('log', 'rice.log')
    end

    def bin_path
      app_path.join(executable ? target : "#{target}.#{RbConfig::CONFIG['DLEXT']}")
    end

    def tmp_path
      Pathname.shared_path('tmp/rice', scope)
    end

    def checksum_path
      app_path.join("#{target}.sha256")
    end

    def extconf_path
      config_path.join('extconf.rb')
    end

    def mkmf_path
      tmp_path.join('make')
    end

    def dst_path
      tmp_path.join('src')
    end

    def pch
      dst_path.join('precompiled.hpp')
    end

    def pch_out
      pch.sub_ext('.hpp.gch')
    end
  end
end
