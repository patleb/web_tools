namespace :lets_encrypt do
  desc 'Create certificate'
  task :create, [:kid] => :environment do |t, args|
    credential = LetsEncrypt.find_or_initialize(args[:kid])
    credential.create
  end

  desc 'Renew certificate'
  task :renew => :environment do
    credential = LetsEncrypt.find_renewable
    credential&.renew
  end

  desc 'Apply certificate'
  task :apply => :environment do
    # TODO nginx recipe
  end
end
