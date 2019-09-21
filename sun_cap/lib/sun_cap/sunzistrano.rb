module Sunzistrano
  module Capistrano
    def self.config(stage)
      if (output = `bundle exec cap #{stage} sun_cap:config --dry-run`.strip).blank?
        puts %{cap #{stage} sun_cap:config => ""}.color(:red).bright
      end
      output.split("\n").each_with_object({}) do |key_value, memo|
        key, value = key_value.strip.split(' ', 2).map(&:strip)
        memo[key] = value unless value.blank? || key == 'DEBUG'
      end
    end
  end
end
