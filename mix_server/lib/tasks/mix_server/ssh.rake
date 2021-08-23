namespace :ssh do
  namespace :cluster do
    desc "Mount cluster with /opt/storage/shared_data on master as /opt/shared_data-{ip}"
    task :mount => :environment do
      host_path = Setting[:server_cluster_data]
      Cloud.server_cluster_ips.zip(Cloud.server_cluster_paths).each do |(ip, mount_path)|
        run_task! 'ssh:mount', ip, host_path, mount_path
      end
    end

    desc "Unmount /opt/shared_data-{ip}"
    task :unmount => :environment do
      Cloud.server_cluster_paths.each do |mount_path|
        run_task! 'ssh:unmount', mount_path
        sh "sudo rmdir #{mount_path}"
      end
    end
  end

  desc 'Mount SSH drive'
  task :mount, [:server, :host_path, :mount_path] => :environment do |t, args|
    sh "sudo mkdir -p #{args[:mount_path]}"
    sh "sudo chown -R #{Setting[:deployer_name]}:#{Setting[:deployer_name]} #{args[:mount_path]}"
    options = %W(
      allow_other
      IdentityFile=/home/#{Setting[:deployer_name]}/.ssh/id_rsa
      StrictHostKeyChecking=no
      compression=no
      Ciphers=aes128-ctr
      reconnect
      ServerAliveInterval=15
      ServerAliveCountMax=3
    )
    sh <<~CMD.squish
      sudo sshfs -o #{options.join(',')},uid=$(id -u #{Setting[:deployer_name]}),gid=$(id -g #{Setting[:deployer_name]})
        #{Setting[:deployer_name]}@#{args[:server]}:#{args[:host_path]} #{args[:mount_path]}
    CMD
  end

  desc 'Unmount SSH drive'
  task :unmount, [:path] => :environment do |t, args|
    sh "sudo fusermount -u #{args[:path]}"
  end
end
