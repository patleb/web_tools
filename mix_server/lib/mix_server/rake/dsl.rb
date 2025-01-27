module Rake
  module DSL
    LS_HEADERS = %i(permissions links owner group size date time zone path)

    def template(src, gems = nil, scope: nil)
      tmp_file = compile(src, gems, scope: scope, deployer: false)
      mv tmp_file, src, force: true
    end

    def compile(src, gems = nil, scope: nil, deployer: true)
      gems ||= Setting.gems.keys
      base_dir = Pathname.new("tmp/#{"#{scope}/" if scope}#{File.dirname(src).delete_prefix('/')}")
      new_file = base_dir.join(File.basename(src))
      FileUtils.mkdir_p base_dir
      FileUtils.chown_R(Setting[:deployer_name], Setting[:deployer_name], base_dir) if deployer && !Rails.env.local?
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

        f.puts ERB.template(source_erb, binding, trim_mode: '-')
      end
      new_file
    end

    def run_ftp_list(match, **options)
      `#{Sh.ftp_list(match, **options)}`.lines.map(&:strip).map(&:split).map do |columns|
        if columns.size == 3
          { size: columns[0].to_i, time: Time.parse_utc(columns[1]), name: columns[2] }.to_hwka
        else
          { time: Time.parse_utc(columns[0]), name: columns[1].delete_suffix('/') }.to_hwka
        end
      end
    end

    def run_ftp_cat(match, **options)
      `#{Sh.ftp_cat(match, **options)}`.strip
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
        row[:updated_at] = Time.parse_utc("#{row.delete(:date)}T#{row.delete(:time)} #{row.delete(:zone)}")
        row
      end
    end

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
  end
end
