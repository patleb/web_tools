namespace :mr_secret do
  desc 'setup secrets.yml, settings.yml, initializers/mr_secret.rb, database.yml and .gitignore files'
  task :setup, [:no_master_key] => :environment do |t, args|
    src, dst = MrSecret.root.join('lib/tasks/templates'), Rails.root

    ['config/initializers/mr_secret.rb', 'config/settings.yml'].each do |file|
      cp src.join(file).to_s, dst.join(file).to_s
    end

    ['config/secrets.yml', 'config/secrets.example.yml'].each do |file|
      dst.join(file).write(ERB.new(src.join('config/secrets.yml.erb').read).result(binding))
    end

    dst.join('config/database.yml').write(ERB.new(src.join('config/database.yml.erb').read).result(binding))

    file = dst.join('.gitignore')
    unless (gitignore = file.read).include? 'config/secrets.yml'
      file.write(gitignore << "\n/config/secrets.yml\n")
    end

    if flag_on? args, :no_master_key
      ['config/credentials.yml.enc', 'config/master.key', 'tmp/development_secret.txt'].each do |file|
        dst.join(file).delete rescue nil
      end
    end
  end

  def app_name
    @app_name ||= Rails.application.engine_name.delete_suffix('_application')
  end

  def app_secret
    SecureRandom.hex(64)
  end

  def generate_password
    SecureRandom.hex(16)
  end
end

namespace :secret do
  task :dump, [:env, :app, :file] do |t, args|
    raise 'argument [:app] must be specified' unless (ENV['RAILS_APP'] = args[:app]).present?
    raise 'argument [:file] must be specified' unless (file = args[:file]).present?
    assign_environment! args

    Pathname.new(file).expand_path.write(Secret.to_yaml)
    puts "[#{ENV['RAILS_APP']}_#{ENV['RAILS_ENV']}] settings written to file [#{file}]"
  end

  desc "encrypt file or ENV['DATA']"
  task :encrypt, [:env, :file] do |t, args|
    assign_environment! args

    if ENV['DATA'].present?
      puts Secret.encrypt(ENV['DATA'])
    else
      puts Secret.encrypt(Pathname.new(args[:file]).expand_path.read)
    end
  end

  desc "decrypt key and optionally output to file"
  task :decrypt, [:env, :key, :file] do |t, args|
    assign_environment! args

    Secret.load
    if args[:file].present?
      Pathname.new(args[:file]).expand_path.write(Secret[args[:key]])
      puts "[#{args[:key]}] key written to file [#{args[:file]}]"
    else
      value =
        if ENV['DATA'].present?
          Secret.decrypt(ENV['DATA'])
        else
          Secret[args[:key]]
        end
      if ENV['ESCAPE'].to_b
        value = value.escape_newlines
      end
      if ENV['UNESCAPE'].to_b
        value = value.unescape_newlines
      end
      puts value
    end
  end

  desc 'escape file newlines'
  task :escape, [:file] do |t, args|
    puts Pathname.new(args[:file]).expand_path.read.escape_newlines
  end

  def assign_environment!(args)
    raise 'argument [:env] must be specified' unless (ENV['RAILS_ENV'] = args[:env]).present?
    ENV['RAILS_APP'] ||= ENV['APP']
    ENV['RAILS_ROOT'] ||= ENV['ROOT']
  end
end
