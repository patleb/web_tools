require 'sun_cap'

module Sunzistrano
  module Capistrano
    def self.config(stage)
      cap = File.file?('bin/cap') ? 'bin/cap' : 'bundle exec cap'
      stdout, stderr, status = Open3.capture3("#{cap} #{stage} sun_cap:config --dry-run")
      if status.success?
        if stdout.present?
          stdout.lines.each_with_object({}) do |key_value, memo|
            key, value = key_value.strip.split(' ', 2).map(&:strip)
            memo[key] = value unless value.blank? || key == 'DEBUG'
          end
        else
          puts %{cap #{stage} sun_cap:config => ""}.red
          {}
        end
      else
        puts stderr.red
        {}
      end
    end
  end
end
