module FtpTasks
  extend Rake::DSL
  extend self

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
      create_mount_path
      sh drive_mount_cmd(args)
    end

    desc 'Unmount FTP drive'
    task :unmount => :environment do
      sh "sudo fusermount -u #{Setting[:ftp_mount_path]}"
    end

    namespace :nohup do
      desc 'Mount FTP drive'
      task :mount, [:user_id, :group_id] => :environment do |t, args|
        create_mount_path
        sh drive_mount_cmd(args, nohup: true)
      end

      desc 'Unmount FTP drive'
      task :unmount => :environment do
        sh "sudo pkill -P $(cat /home/#{Setting[:deployer_name]}/curlftpfs.pid)"
      end
    end

    namespace :db do
      desc 'Backup database and upload dump under backup directory'
      task :backup, [:skip_ftp] => :environment do |t, args|
        Db::Pg::Dump.new(self, t, args, version: true, split: true, md5: true, physical: true).run!
        puts_info '[DUMP]', 'done'
        unless flag_on? args, :skip_ftp
          sh Sh.ftp_remove(backup_folder.join('dump-old/*')), verbose: false
          sh Sh.ftp_rename(backup_folder.join('dump/*'), backup_folder.join('dump-old/')), verbose: false
          sh Sh.ftp_upload(backup_folder.join('dump/*'), backup_root, sudo: true, parallel: 10), verbose: false
        end
      end

      desc 'Download dump under backup directory and restore database'
      task :restore, [:skip_ftp] => :environment do |t, args|
        unless flag_on? args, :skip_ftp
          local_md5 = `sudo cat #{Setting[:backup_dir].join('dump/*.md5')}`.strip
          remote_md5 = run_ftp_list(backup_folder.join('dump/*.md5')).map{ |file| file[:name] }
          remote_md5 = remote_md5.presence ? run_ftp_cat(remote_md5.join(' ')) : ''
          if local_md5.blank? || local_md5 != remote_md5
            sh "sudo rm -f #{Setting[:backup_dir].join('dump/*')}" if local_md5.present?
            sh Sh.ftp_download(backup_folder.join('dump/*'), backup_root, sudo: true, parallel: 10), verbose: false
          end
        end
        Db::Pg::Restore.new(self, t, args, path: Setting[:backup_dir].join('dump/base.tar.gz-*')).run!
      end

      namespace :backups do
        desc 'mirror dumps'
        task :mirror => :environment do
          sh Sh.ftp_mirror(backup_folder.join('dump_*'), backup_root, sudo: true, parallel: 10), verbose: false
        end

        desc 'restore dated dump'
        task :restore, [:date, :version] => :environment do |t, args|
          raise 'must specify a date' unless (date = args[:date]&.tr('-', '_')).present?
          raise 'must specify git short hash' unless (version = args[:version]).present?
          dump_name = "dump_#{date}-#{version}"
          sh Sh.ftp_download(backup_folder.join(dump_name), backup_root, sudo: true, parallel: 10), verbose: false
          Db::Pg::Restore.new(self, t, args, path: Setting[:backup_dir].join("#{dump_name}.pg.gz-*")).run!
        end
      end
    end

    namespace :osquery do
      namespace :logs do
        desc 'mirror osquery logs'
        task :mirror => :environment do
          path = "#{MixLog.config.osquery_log_path}*"
          sh Sh.ftp_mirror(path, backup_root, sudo: true, parallel: 10), verbose: false
        end
      end
    end
  end

  def create_mount_path
    sh "sudo mkdir -p #{Setting[:ftp_mount_path]}"
    sh "sudo chown -R #{Setting[:deployer_name]}:#{Setting[:deployer_name]} #{Setting[:ftp_mount_path]}"
  end

  def drive_mount_cmd(args, nohup: false)
    <<~CMD.squish.gsub('\\', '\\\\\\')
      sudo nohup curlftpfs #{'-f' if nohup} -o '#{drive_options(args).join(',')}'
        '#{Setting[:ftp_host]}:#{Setting[:ftp_drive_path]}' #{Setting[:ftp_mount_path]}
        >> /home/#{Setting[:deployer_name]}/curlftpfs.log 2>&1
        #{"& sleep 1 && echo $! > /home/#{Setting[:deployer_name]}/curlftpfs.pid" if nohup}
    CMD
  end

  def drive_options(args)
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

  def backup_folder
    @backup_folder ||= Setting[:backup_dir].basename
  end

  def backup_root
    @backup_root ||= Setting[:backup_dir].dirname
  end
end
