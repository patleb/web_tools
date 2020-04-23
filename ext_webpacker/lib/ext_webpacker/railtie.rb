require "ext_ruby"

module ExtWebpacker
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_webpacker.rake'
    end

    initializer 'ext_webpacker.bootstrap', before: 'webpacker.proxy' do
      require 'ext_webpacker/webpacker'
    end
  end
end
