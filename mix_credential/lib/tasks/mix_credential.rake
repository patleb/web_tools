namespace :credential do
  namespace :lets_encrypt do
    desc 'Create certificate'
    task :create, [:kid] => :environment do |t, args|
      credential = Credentials::LetsEncrypt.find_or_initialize(args[:kid])
      credential.create
    end

    desc 'Renew certificate'
    task :renew => :environment do
      next unless (credential = Credentials::LetsEncrypt.find_renewable)
      credential.renew
      run_task 'credential:lets_encrypt:apply'
    end

    desc 'Apply certificate'
    task :apply => :environment do
      credential = Credentials::LetsEncrypt.find_current!
      nginx_ssl_path = "/etc/nginx/ssl/#{credential.server_host}.server"
      sh "echo '#{credential.decrypted(:key).escape_newlines}' | sudo tee #{nginx_ssl_path}.key > /dev/null"
      sh "sudo chmod 600 #{nginx_ssl_path}.key"
      sh "echo '#{credential.decrypted(:crt).escape_newlines}' | sudo tee #{nginx_ssl_path}.crt > /dev/null"
      sh "sudo systemctl reload nginx", verbose: false
    end

    desc 'Revoke certificate'
    task :revoke, :environment do
      credential = Credentials::LetsEncrypt.find_current!
      credential.revoke
    end
  end
end
