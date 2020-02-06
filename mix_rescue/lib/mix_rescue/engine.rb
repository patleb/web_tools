module MixRescue
  class Engine < ::Rails::Engine
    require 'mix_notifier'
    require 'mix_rescue/notice/with_rescue'

    initializer 'mix_rescue.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
