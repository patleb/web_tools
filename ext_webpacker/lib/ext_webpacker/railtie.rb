require "ext_ruby"

module ExtWebpacker
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_webpacker.rake'
    end
  end
end
