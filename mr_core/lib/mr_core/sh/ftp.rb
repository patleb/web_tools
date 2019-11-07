module Sh::Ftp
  def execute_ftp_list(match)
    `#{ftp_list(match)}`.lines.map(&:strip).map(&:split).map do |columns|
      { size: columns[0].to_i, time: DateTime.parse(columns[1]), name: columns[2] }.with_indifferent_access
    end
  end

  def execute_ftp_cat(match)
    `#{ftp_cat(match)}`.strip
  end

  def ftp_list(match)
    ftp "cls #{match} --sort=name --size --date --time-style=%Y-%m-%dT%H:%M:%S%z --sortnocase"
  end

  def ftp_cat(match)
    ftp "cat #{match}"
  end

  def ftp_download(match, client_dir)
    ftp "mget -c -d #{match} -O #{client_dir}"
  end

  def ftp_upload(match, client_dir)
    ftp "lcd #{client_dir}; mput -c -d #{match}"
  end

  def ftp_remove(match)
    ftp "mrm -r #{match}"
  end

  def ftp_rename(old_name, new_name)
    ftp "mv #{old_name} #{new_name}"
  end

  def ftp(command)
    <<~SH
      lftp -u '#{Setting[:ftp_username]},#{Setting[:ftp_password]}' #{Setting[:ftp_host]}:#{Setting[:ftp_host_path]} <<-FTP
        #{command}
      FTP
    SH
  end
end
