module Sh::Ftp
  def execute_ftp_list(match)
    `#{ftp_list(match)}`.lines.map(&:strip).map(&:split).map do |columns|
      { size: columns[0].to_i, time: DateTime.parse(columns[1]), name: columns[2] }.with_indifferent_access
    end
  end

  def ftp_list(match)
    ftp("cls #{match} --sort=name --size --date --time-style=%Y-%m-%dT%H:%M:%S%z --sortnocase")
  end

  def ftp_download(match, client_dir = nil)
    ftp "mget -c -d #{match} -O #{client_dir || Setting[:ftp_mount_path]}"
  end

  def ftp_upload(match, client_dir = nil)
    ftp "lcd #{client_dir || Setting[:ftp_mount_path]}; mput -c -d #{match}"
  end

  def ftp_remove(match)
    ftp "mrm -r #{match}"
  end

  def ftp_rename(old_name, new_name)
    lftp "mv #{old_name} #{new_name}"
  end

  def ftp(command)
    "lftp -u '#{Setting[:ftp_username]},#{Setting[:ftp_password]}' #{Setting[:ftp_host]}:#{Setting[:ftp_host_path]} <<-FTP\n" \
      "#{command}\n" \
    "FTP"
  end
end
