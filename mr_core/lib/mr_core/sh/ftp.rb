module Sh::Ftp
  def ftp_list(match)
    ftp "ls #{match}"
  end

  def ftp_download(match)
    ftp "mget -c -d #{match} -O #{Setting[:ftp_mount_path]}"
  end

  def ftp_upload(match)
    ftp "lcd #{Setting[:ftp_mount_path]}; mput -c -d #{match}"
  end

  def ftp_remove(match)
    ftp "mrm -r #{match}"
  end

  def ftp_rename(old_name, new_name)
    lftp "mv #{old_name} #{new_name}"
  end

  def ftp(command)
    "lftp -u '#{Setting[:ftp_username]},#{Setting[:ftp_password]}' #{Setting[:ftp_host]}:#{Setting[:ftp_host_path]} <<-FTP\n#{command}\nFTP"
  end
end
