namespace :lets_encrypt do
  desc 'Create certificate'
  task :create, [:kid] => :environment do |t, args|
    credential = LetsEncrypt.find_or_initialize(args[:kid])
    credential.create
  end

  desc 'Renew certificate'
  task :renew => :environment do
    next unless (credential = LetsEncrypt.find_renewable)
    credential.renew
    nginx_ssl_path = "/etc/nginx/ssl/#{credential.server_host}"
    sh "sudo echo -e '#{credential.decrypted(:key).escape_newlines}' > #{nginx_ssl_path}.server.key", verbose: false
    sh "sudo echo -e '#{credential.decrypted(:crt).escape_newlines}' > #{nginx_ssl_path}.server.crt", verbose: false
    sh "sudo systemctl reload nginx", verbose: false
  end

  desc 'Revoke certificate'
  task :revoke, :environment do
    credential = LetsEncrypt.find_current!
    credential.revoke
  end
end
