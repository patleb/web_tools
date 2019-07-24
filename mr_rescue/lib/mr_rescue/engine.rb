require "mr_rescue/rescue_error"

module MrRescue
  class Engine < ::Rails::Engine
    initializer 'mr_rescue.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
