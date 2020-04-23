require "ext_ruby"

module ExtWebpacker
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_webpacker.rake'
    end

    initializer 'ext_webpacker.bootstrap', after: 'webpacker.bootstrap' do
      require 'ext_webpacker/webpacker'
    end
  end
end
