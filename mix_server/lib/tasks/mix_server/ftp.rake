namespace :ftp do
  desc 'List files matching the expression'
  task :list, [:match] => :environment do |t, args|
    sh Sh.ftp_list(args[:match]), verbose: false
  end

  desc 'Download files matching the expression'
  task :download, [:match, :client_dir, :sudo] => :environment do |t, args|
    sh Sh.ftp_download(args[:match], args[:client_dir], sudo: (flag_on? args, :sudo)), verbose: false
  end

  desc 'Upload files matching the expression'
  task :upload, [:match, :client_dir, :sudo] => :environment do |t, args|
    sh Sh.ftp_upload(args[:match], args[:client_dir], sudo: (flag_on? args, :sudo)), verbose: false
  end

  desc 'Remove files matching the expression'
  task :remove, [:match] => :environment do |t, args|
    sh Sh.ftp_remove(args[:match]), verbose: false
  end

  desc 'Rename file or directory'
  task :rename, [:old_name, :new_name] => :environment do |t, args|
    sh Sh.ftp_rename(args[:old_name], args[:new_name]), verbose: false
  end

  desc 'Mount FTP drive'
  task :mount, [:user_id, :group_id] => :environment do |t, args|
    ftp_create_mount_path
    sh ftp_drive_mount_cmd(args)
  end

  desc 'Unmount FTP drive'
  task :unmount => :environment do
    sh "sudo fusermount -u #{Setting[:ftp_mount_path]}"
  end

  namespace :nohup do
    desc 'Mount FTP drive'
    task :mount, [:user_id, :group_id] => :environment do |t, args|
      ftp_create_mount_path
      sh ftp_drive_mount_cmd(args, nohup: true)
    end

    desc 'Unmount FTP drive'
    task :unmount => :environment do
      sh "sudo pkill -P $(cat /home/#{Setting[:deployer_name]}/curlftpfs.pid)"
    end
  end

  def ftp_create_mount_path
    sh "sudo mkdir -p #{Setting[:ftp_mount_path]}"
    sh "sudo chown -R #{Setting[:deployer_name]}:#{Setting[:deployer_name]} #{Setting[:ftp_mount_path]}"
  end

  def ftp_drive_mount_cmd(args, nohup: false)
    <<~CMD.squish.gsub('\\', '\\\\\\')
      sudo nohup curlftpfs #{'-f' if nohup} -o '#{ftp_drive_options(args).join(',')}'
        '#{Setting[:ftp_host]}:#{Setting[:ftp_drive_path]}' #{Setting[:ftp_mount_path]}
        >> /home/#{Setting[:deployer_name]}/curlftpfs.log 2>&1
        #{"& sleep 1 && echo $! > /home/#{Setting[:deployer_name]}/curlftpfs.pid" if nohup}
    CMD
  end

  def ftp_drive_options(args)
    user_id = args[:user_id] || Setting[:deployer_id] || 1001
    group_id = args[:group_id] || user_id
    %W(
      allow_other
      ssl
      no_verify_peer
      no_verify_hostname
      nonempty
      user=#{Setting[:ftp_username]}:#{Setting[:ftp_password]}
    ).reject(&:blank?).concat(%W(
      uid=#{user_id}
      gid=#{group_id}
    ))
  end
end
