require "mr_template/configuration"

module ActionPresenter
  autoload :Base, 'mr_template/action_presenter/base'
end

module MrTemplate
  class Engine < ::Rails::Engine
    require 'query_diet' if Rails.env.development?
    require 'nestive'
    require 'mr_template/active_support/core_ext'

    config.before_configuration do
      require 'mr_template/rails/application'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'before_render'
      require 'mr_template/action_controller/base'
    end

    ActiveSupport.on_load(:action_view) do
      require 'mr_template/action_view/helpers/tag_helper/tag_builder/with_data_option'
      require 'mr_template/action_view/template_renderer/with_presenter'
    end
  end
end
