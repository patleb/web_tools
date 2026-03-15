namespace! :certificate do
  namespace :lets_encrypt do
    desc 'Create or renew certificate'
    task :create_or_renew => :environment do
      next unless Rails.env.production? || Rails.env.staging?
      next unless Setting[:server_ssl] && Setting[:lets_encrypt] != false
      next unless (certificate = Certificates::LetsEncrypt.create_or_renew)
      update_nginx_ssl certificate
    end

    desc 'Restore certificate from DB'
    task :restore => :environment do
      certificate = Certificates::LetsEncrypt.find_current!
      update_nginx_ssl certificate
    end

    desc 'Revoke certificate'
    task :revoke => :environment do
      certificate = Certificates::LetsEncrypt.find_current!
      certificate.revoke
    end
  end

  def update_nginx_ssl(certificate)
    nginx_ssl_path = "/etc/nginx/ssl/#{certificate.server_host}.server"
    system "echo '#{certificate.decrypted(:key).escape_newlines}' | sudo tee #{nginx_ssl_path}.key > /dev/null"
    sh "sudo chmod 600 #{nginx_ssl_path}.key", verbose: false
    system "echo '#{certificate.decrypted(:crt).escape_newlines}' | sudo tee #{nginx_ssl_path}.crt > /dev/null"
    sh "sudo systemctl reload nginx", verbose: false
  end
end
