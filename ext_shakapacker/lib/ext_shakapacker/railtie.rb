require "ext_ruby"

module ExtShakapacker
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/ext_shakapacker.rake'
    end

    initializer 'ext_shakapacker.bootstrap', before: 'shakapacker.proxy' do
      require 'ext_shakapacker/shakapacker'
    end

    ActiveSupport.on_load(:action_view) do
      require 'ext_shakapacker/shakapacker/helper'
    end
  end
end
