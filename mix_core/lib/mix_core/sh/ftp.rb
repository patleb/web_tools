module Sh::Ftp
  def ftp_list(match, **options)
    ftp "cls #{match} --sort=name --size --date --time-style=%Y-%m-%dT%H:%M:%S%z --sortnocase", **options
  end

  def ftp_cat(match, **options)
    ftp "cat #{match}", **options
  end

  def ftp_download(match, client_dir, parallel: nil, **options)
    files = Array.wrap(match)
    parallel ||= files.size if files.size > 1
    ftp "mget -O #{client_dir} #{"-P #{parallel}" if parallel} -c -d #{files.join(' ')}", **options
  end

  def ftp_upload(match, client_dir, parallel: nil, **options)
    files = Array.wrap(match)
    parallel ||= files.size if files.size > 1
    ftp "lcd #{client_dir}; mput #{"-P #{parallel}" if parallel} -c -d #{files.join(' ')}", **options
  end

  def ftp_remove(match, **options)
    ftp "mrm -r #{match}", **options
  end

  def ftp_rename(old_name, new_name, **options)
    ftp "mv #{old_name} #{new_name}", **options
  end

  def ftp(command, sudo: false, username: Setting[:ftp_username], password: Setting[:ftp_password], host: Setting[:ftp_host], host_path: Setting[:ftp_host_path])
    <<~SH
      #{'sudo' if sudo} lftp -u '#{username},#{password}' #{host}:#{host_path} <<-FTP
        #{command}
      FTP
    SH
  end
end
