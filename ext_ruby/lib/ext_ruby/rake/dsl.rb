module Rake
  module DSL
    def keep(root)
      root = Pathname.new(root)
      mkdir_p root
      touch   root.join('.keep')
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

    def app_name
      Rails.application.name
    end

    def app_secret
      SecureRandom.hex(64)
    end

    def generate_password
      SecureRandom.hex(16)
    end
  end
end
