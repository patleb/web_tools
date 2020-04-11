require "mix_template/configuration"

module ActionPresenter
  autoload :Base, 'mix_template/action_presenter/base'
end

module MixTemplate
  class Engine < ::Rails::Engine
    require 'query_diet' if Rails.env.development?
    require 'nestive'
    require 'mix_template/active_support/core_ext'

    config.before_configuration do
      require 'mix_template/rails/application'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mix_template/action_controller/base'
    end

    ActiveSupport.on_load(:action_view) do
      require 'mix_template/action_view/helpers/sanitize_helper'
      require 'mix_template/action_view/helpers/tag_helper/tag_builder/with_data_option'
      require 'mix_template/action_view/template_renderer/with_presenter'
    end

    initializer 'mix_template.tag_helper', before: 'nestive.initialize' do
      ActiveSupport.on_load(:action_view) do
        require 'helpers/mix_template/tag_helper'
        include MixTemplate::TagHelper
      end
    end

    initializer 'mix_template.layout_helper', after: 'nestive.initialize' do
      ActiveSupport.on_load(:action_view) do
        require 'helpers/mix_template/layout_helper'
        include MixTemplate::LayoutHelper
      end
    end
  end
end
