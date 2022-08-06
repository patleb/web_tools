namespace :ssh do
  namespace :cluster do
    desc "Mount cluster with /opt/storage/shared_data on master as /opt/shared_data-{ip}"
    task :mount => :environment do
      host_path = Setting[:server_cluster_data]
      Cloud.server_cluster_paths.each do |ip, mount_path|
        run_task! 'ssh:mount', ip, host_path, mount_path
      end
    end

    desc "Unmount /opt/shared_data-{ip}"
    task :unmount => :environment do
      Cloud.server_cluster_paths.each do |_ip, mount_path|
        run_task! 'ssh:unmount', mount_path
        sh "sudo rmdir #{mount_path}"
      end
    end

    desc 'Write cluster_ssh file for parallel-ssh'
    task :parallelize => :environment do
      File.write('/home/deployer/ssh_cluster', Setting[:server_cluster_ips].map{ |ip| "deployer@#{ip}" }.join("\n") + "\n")
    end
  end

  desc 'Mount SSH drive'
  task :mount, [:server, :host_path, :mount_path] => :environment do |t, args|
    sh "sudo mkdir -p #{args[:mount_path]}"
    sh "sudo chown -R deployer:deployer #{args[:mount_path]}"
    options = %W(
      allow_other
      IdentityFile=/home/deployer/.ssh/id_rsa
      StrictHostKeyChecking=no
      compression=no
      Ciphers=aes128-ctr
      reconnect
      ServerAliveInterval=15
      ServerAliveCountMax=3
    )
    sh <<~CMD.squish
      sudo sshfs -o #{options.join(',')},uid=$(id -u deployer),gid=$(id -g deployer)
        deployer@#{args[:server]}:#{args[:host_path]} #{args[:mount_path]}
    CMD
  end

  desc 'Unmount SSH drive'
  task :unmount, [:path] => :environment do |t, args|
    sh "sudo fusermount -u #{args[:path]}"
  end

  desc 'Add owner private key to development machine'
  task :add, [:env, :force] => :environment do |t, args|
    with_stage(args) do
      path = "$HOME/.ssh/id_rsa-#{Setting.app}-#{Setting.env}.pem"
      if flag_on? args, :force
        sh %{echo "#{Setting[:owner_private_key]}" > #{path}}, verbose: false
        sh %{chmod 600 #{path}}, verbose: false
      end
      sh %{ssh-add #{path} 2> /dev/null}, verbose: false
      puts "ssh key [#{path}] added"
    end
  end
end
