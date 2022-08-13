# TODO https://gist.github.com/metaskills/8691558
module Rake
  module DSL
    LS_HEADERS = %i(permissions links owner group size date time zone path)

    def namespace!(name = nil, &block)
      module_name = "#{name.to_s.camelize}_Tasks"
      with_scope   = self.class.const_get(module_name) if self.class.const_defined? module_name
      with_scope ||= self.class.const_set(module_name, Module.new)
      with_scope.module_eval do
        extend Rake::DSL
        extend self
        namespace name do
          instance_eval(&block)
        end
      end
    end

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

    def template(src, gems = nil, scope: nil)
      tmp_file = compile(src, gems, scope: scope, deployer: false)
      mv tmp_file, src, force: true
    end

    def compile(src, gems = nil, scope: nil, deployer: true)
      gems ||= Setting.gems.keys
      base_dir = Pathname.new("tmp/#{"#{scope}/" if scope}#{File.dirname(src).delete_prefix('/')}")
      new_file = base_dir.join(File.basename(src))
      FileUtils.mkdir_p base_dir
      FileUtils.chown_R('deployer', 'deployer', base_dir) if deployer && !(defined?(Rails.env) && Rails.env.dev_or_test?)
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
      @_app_name ||= Setting.default_app
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end

    def puts_info(tag, text = nil, started_at: nil)
      unless respond_to?(:distance_of_time) || self.class.include?(DOTIW::Methods)
        self.class.include DOTIW::Methods
      end
      tag = "[#{tag}]" unless tag.start_with?('[') && tag.end_with?(']')
      text = "[#{Time.current.utc}]#{tag.full_underscore.upcase}[#{Process.pid}] #{text}"
      text = "#{text} -- : #{distance_of_time (Concurrent.monotonic_time - started_at).seconds.ceil(3)}" if started_at
      puts text
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

    def maintenance_message(duration = nil)
      time =
        case duration
        when /\d+\.weeks?$/   then duration.to_i.weeks.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.days?$/    then duration.to_i.day.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.hours?$/   then duration.to_i.hours.from_now.to_s.sub(/\d{2}:\d{2} UTC$/, '00:00 UTC')
        when /\d+\.minutes?$/ then duration.to_i.minutes.from_now.to_s.sub(/\d{2} UTC$/, '00 UTC')
        when /\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}/ then "#{duration} UTC"
        when nil
        else
          raise 'invalid :duration'
        end
      "Should be back around #{time}".gsub(' ', '&nbsp;').gsub('-', '&#8209;') if time
    end
    module_function :maintenance_message

    def with_stage!(args, &block)
      raise 'argument [:app] must be specified' unless args[:app].present?
      with_stage(args, &block)
    end

    def with_stage(args)
      raise 'argument [:env] must be specified' unless args[:env].present?
      Setting.with(env: args[:env], app: args[:app]) do
        yield
      end
    end
  end
end
