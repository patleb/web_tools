require 'sun_cap'

module Sunzistrano
  module Capistrano
    def self.config(stage)
      stdout, stderr, status = Open3.capture3("bundle exec cap #{stage} sun_cap:config --dry-run")
      if status.success?
        if stdout.present?
          stdout.lines.each_with_object({}) do |key_value, memo|
            key, value = key_value.strip.split(' ', 2).map(&:strip)
            memo[key] = value unless value.blank? || key == 'DEBUG'
          end
        else
          puts %{cap #{stage} sun_cap:config => ""}.color(:red).bright
          {}
        end
      else
        puts stderr.color(:red).bright
        {}
      end
    end
  end
end
