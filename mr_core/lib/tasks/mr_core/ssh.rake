namespace :ssh do
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
