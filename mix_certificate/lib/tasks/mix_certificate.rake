namespace :certificate do
  namespace :lets_encrypt do
    desc 'Create certificate'
    task :create => :environment do
      certificate = Certificates::LetsEncrypt.find_or_initialize
      certificate.create
    end

    desc 'Renew certificate'
    task :renew => :environment do
      next if Rails.env.vagrant?
      next unless (certificate = Certificates::LetsEncrypt.find_renewable)
      certificate.renew
      run_task 'certificate:lets_encrypt:apply'
    end

    desc 'Apply certificate'
    task :apply => :environment do
      certificate = Certificates::LetsEncrypt.find_current!
      nginx_ssl_path = "/etc/nginx/ssl/#{certificate.server_host}.server"
      sh "echo '#{certificate.decrypted(:key).escape_newlines}' | sudo tee #{nginx_ssl_path}.key > /dev/null"
      sh "sudo chmod 600 #{nginx_ssl_path}.key"
      sh "echo '#{certificate.decrypted(:crt).escape_newlines}' | sudo tee #{nginx_ssl_path}.crt > /dev/null"
      sh "sudo systemctl reload nginx", verbose: false
    end

    desc 'Revoke certificate'
    task :revoke => :environment do
      certificate = Certificates::LetsEncrypt.find_current!
      certificate.revoke
    end
  end
end
