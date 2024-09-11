require 'mix_admin/configuration'
require 'mix_admin/routes'

module MixAdmin
  class Engine < ::Rails::Engine
    require 'mix_global'
    require 'mix_user'
    require 'mix_admin/active_support/core_ext/numeric/conversions'
    require 'mix_admin/active_support/core_ext/object/full_symbolize'
    require 'mix_admin/active_support/core_ext/string'
    require 'mix_admin/rails/engine'

    config.before_configuration do
      require 'mix_admin/active_model/name/with_admin'
    end

    initializer 'mix_admin.routes', before: 'ext_rails.routes' do |app|
      app.routes.prepend do
        MixAdmin::Routes.draw(self)
      end
    end

    ActiveSupport.on_load(:active_record) do
      require 'mix_admin/active_record/base/with_admin'
    end
  end
end
