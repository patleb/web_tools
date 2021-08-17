# TODO rotate :secret_key_base
namespace :setting do
  task :context => :environment do
    puts "{ env: #{Setting.rails_env}, app: #{Setting.rails_app} }"
  end

  task :dump, [:env, :app, :file] do |t, args|
    raise 'argument [:app] must be specified' unless (ENV['RAILS_APP'] = args[:app]).present?
    raise 'argument [:file] must be specified' unless (file = args[:file]).present?
    assign_environment! args

    Setting.with(env: ENV['RAILS_ENV']){ Pathname.new(file).expand_path.write(Setting.to_yaml) }
    puts "[#{ENV['RAILS_APP']}_#{ENV['RAILS_ENV']}] settings written to file [#{file}]"
  end

  desc "encrypt file or ENV['DATA'] --> wrap with double quotes for escaped newlines"
  task :encrypt, [:env, :file] do |t, args|
    assign_environment! args

    Setting.with(env: ENV['RAILS_ENV']) do
      if ENV['DATA'].present?
        puts Setting.encrypt(ENV['DATA'])
      else
        puts Setting.encrypt(Pathname.new(args[:file]).expand_path.read)
      end
    end
  end

  desc "decrypt key and optionally output to file"
  task :decrypt, [:env, :key, :file] do |t, args|
    assign_environment! args

    Setting.with(env: ENV['RAILS_ENV']) do
      if args[:file].present?
        Pathname.new(args[:file]).expand_path.write(Setting[args[:key]])
        puts "[#{args[:key]}] key written to file [#{args[:file]}]"
      else
        value =
          if ENV['DATA'].present?
            Setting.decrypt(ENV['DATA'])
          else
            Setting[args[:key]]
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
  end

  desc 'escape file newlines'
  task :escape, [:file] do |t, args|
    puts Pathname.new(args[:file]).expand_path.read.escape_newlines
  end
end
