module Rake
  module DSL
    LS_HEADERS = %i(permissions links owner group size date time zone path)

    def keep(root, force: false)
      root = Pathname.new(root)
      mkdir_p root
      touch root.join('.keep') if force || root.empty?
    end

    def gitignore(root, ignore, verbose: true)
      file = Pathname.new(root).join('.gitignore')
      unless (gitignore = file.read).match? /^#{ignore.escape_regex}$/
        Rake.rake_output_message "gitignore #{ignore}" if verbose
        write file, (gitignore << "\n#{ignore}"), verbose: false
      end
    end

    def write(dst, value, verbose: true)
      Rake.rake_output_message "write #{dst}" if verbose
      Pathname.new(dst).write(value)
    end

    def template(src, gems = nil)
      tmp_file = compile(src, gems)
      mv tmp_file, src, force: true
    end

    def compile(src, gems = nil, rake: true)
      gems ||= Setting.gems.keys
      base_dir = Pathname.new("tmp/#{File.dirname(src).delete_prefix('/')}")
      new_file = base_dir.join(File.basename(src))
      FileUtils.mkdir_p base_dir
      FileUtils.chown_R('deployer', 'deployer', base_dir) if rake
      File.open(new_file, 'w') do |f|
        source_erb = "#{src}.erb"

        unless File.exist? source_erb
          gems.each do |name|
            if (root = Gem.root(name))
              if (path = root.join(source_erb)).exist?
                source_erb = path
                break
              end
            end
          end
        end

        f.puts ERB.new(File.read(source_erb), nil, '-').result(binding)
      end
      new_file
    end
    module_function :compile

    def app_name
      @_app_name ||= File.read('config/application.rb')[/^module \w+$/].split.last.underscore
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end

    def puts_info(tag, text = nil)
      tag = "[#{tag}]" unless tag.start_with?('[') && tag.end_with?(']')
      puts "[#{Time.current.utc}]#{tag.full_underscore.upcase}[#{Process.pid}] #{text}"
    end

    def free_local_ip
      require 'socket'
      network = ''
      networks = [''].concat Socket.getifaddrs.map{ |i| i.addr.ip_address.sub(/\.\d+$/, '') if i.addr.ipv4? }.compact
      loop do
        break unless networks.include?(network)
        network = "192.168.#{rand(4..254)}"
      end
      "#{network}.#{rand(2..254)}"
    end

    def git_repo
      `git remote -v | head -n1 | awk '{ print $2; }'`.strip
    end

    def sudo_ls(path)
      `sudo ls --full-time -t #{path}.* | grep #{path}`.lines(chomp: true).map do |line|
        row = LS_HEADERS.zip(line.split).to_h
        permissions = ''
        row[:permissions].chars.drop(1).each_slice(3) do |rwx|
          permissions << rwx.reverse.each_with_object([]).with_index do |(type, group), i|
            group << (type != '-').to_i * (2 ** i)
          end.sum.to_s
        end
        row[:permissions] = permissions.to_i
        row[:size] = row[:size].to_i
        row[:updated_at] = Time.parse("#{row.delete(:date)}T#{row.delete(:time)} #{row.delete(:zone)}")
        row
      end
    end

    def flag_on?(args, name)
      return unless args.respond_to? :key?
      value = args[name]
      (value.to_s == name.to_s) || value.to_b
    end
    module_function :flag_on?

    def assign_environment!(args)
      raise 'argument [:env] must be specified' unless (ENV['RAILS_ENV'] = args[:env]).present?
      ENV['RAILS_APP'] ||= ENV['APP']
      ENV['RAILS_ROOT'] ||= ENV['ROOT']
    end
  end
end
