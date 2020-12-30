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

    def template(src)
      ERB.template(src, binding)
    end

    def app_name
      Rails.application.name
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end

    def puts_info(tag, text = nil)
      puts "[#{Time.current.utc}][#{tag.full_underscore.upcase}][#{Process.pid}] #{text}"
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
  end
end
