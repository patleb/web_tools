require "mr_rescue/rescue_error"

module MrRescue
  class Engine < ::Rails::Engine
    require 'mr_notifier'
    require 'mr_rescue/notice/with_rescue'

    initializer 'mr_rescue.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
