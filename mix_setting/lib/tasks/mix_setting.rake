# TODO rotate :secret_key_base
namespace :setting do
  task :context => :environment do
    puts "{ env: #{Setting.env}, app: #{Setting.app} }"
  end

  task :dump, [:env, :app, :file] do |t, args|
    raise 'argument [:file] must be specified' unless (file = args[:file]).present?
    with_stage! args do
      Pathname.new(file).expand_path.write(Setting.to_yaml)
      puts "[#{Setting.app}_#{Setting.env}] settings written to file [#{file}]"
    end
  end

  desc "encrypt file or ENV['DATA'] --> wrap with double quotes for escaped newlines"
  task :encrypt, [:env, :file] do |t, args|
    with_stage(args) do
      if ENV['DATA'].present?
        puts Setting.encrypt(ENV['DATA'])
      else
        puts Setting.encrypt(Pathname.new(args[:file]).expand_path.read)
      end
    end
  end

  desc "decrypt key and optionally output to file"
  task :decrypt, [:env, :key, :file] do |t, args|
    with_stage(args) do
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
