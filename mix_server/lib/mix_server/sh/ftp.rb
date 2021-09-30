module Sh::Ftp
  def ftp_mirror(match, base_dir, parallel: nil, **options)
    ftp "mkdir -pf #{base_dir}; mirror -R -O #{base_dir} #{"-P #{parallel}" if parallel && parallel.to_i > 1} -c -e -f #{match}", **options
  end

  def ftp_list(match, **options)
    ftp "cls #{match} --sort=name --size --date --time-style=%Y-%m-%dT%H:%M:%S%z --sortnocase", **options
  end

  def ftp_cat(match, **options)
    ftp "cat #{match}", **options
  end

  def ftp_download(match, base_dir, parallel: nil, **options)
    files = Array.wrap(match)
    parallel ||= files.size if files.size > 1
    ftp "mget -O #{base_dir} #{"-P #{parallel}" if parallel && parallel.to_i > 1} -c -d #{files.join(' ')}", **options
  end

  def ftp_upload(match, base_dir, parallel: nil, **options)
    files = Array.wrap(match)
    parallel ||= files.size if files.size > 1
    ftp "mkdir -pf #{base_dir}; lcd #{base_dir}; mput #{"-P #{parallel}" if parallel && parallel.to_i > 1} -c -d #{files.join(' ')}", **options
  end

  def ftp_remove(match, **options)
    match = match.to_s.dup
    if match.delete_suffix! '/*'
      ftp "rm -rf #{match}; mkdir -f #{match}", **options
    else
      ftp "rm #{match}", **options
    end
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
