namespace :certificate do
  namespace :lets_encrypt do
    desc 'Create or renew certificate'
    task :create_or_renew => :environment do
      next unless Rails.env.production? || Rails.env.staging?
      next unless Setting[:server_ssl] && !Setting[:skip_lets_encrypt]
      next unless (certificate = Certificates::LetsEncrypt.create_or_renew)
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
