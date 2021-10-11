namespace :secrets do
  desc 'encrypt secrets.yml with age'
  task :encrypt => :environment do
    recipients = Setting[:authorized_keys].map{ |key| "-r '#{key}'" }.join(' ')
    sh "age #{recipients} -o #{Rails.root}/config/secrets.yml.age --armor #{Rails.root}/config/secrets.yml", verbose: false
  end

  desc 'decrypt secrets.yml.age'
  task :decrypt, [:id_rsa] => :environment do |t, args|
    identity = args[:id_rsa] || "$HOME/.ssh/id_rsa"
    sh "age -d -i #{identity} #{Rails.root}/config/secrets.yml.age > #{Rails.root}/config/secrets.yml"
  end
end
