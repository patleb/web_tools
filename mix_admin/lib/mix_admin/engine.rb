require 'mix_admin/configuration'
require 'mix_admin/routes'
require 'mix_user'
require 'redcarpet'

module Admin
  extend ActiveSupport::Autoload

  autoload :Action
  autoload :Configurable
  autoload :Field
  autoload :Group
  autoload :Model
  autoload :Section

  module Actions
    extend ActiveSupport::Autoload

    autoload :Delete
    autoload :Edit
    autoload :Export
    autoload :Index
    autoload :New
    autoload :Restore
    autoload :Show
    autoload :ShowInApp
    autoload :Trash
    autoload :Upload
  end

  module Fields
    extend ActiveSupport::Autoload

    autoload :Association
    autoload :BelongsTo
    autoload :BelongsToListParent
    autoload :BelongsToPolymorphic
    autoload :Boolean
    autoload :Bytes
    autoload :Code
    autoload :Date
    autoload :DateTime
    autoload :Decimal
    autoload :Discarded
    autoload :Enum
    autoload :EnumSti
    autoload :ForeignKey
    autoload :HasMany
    autoload :HasOne
    autoload :Hidden
    autoload :Html
    autoload :Integer
    autoload :Interval
    autoload :Json
    autoload :Money
    autoload :Password
    autoload :String
    autoload :Text
    autoload :Time
    autoload :Timestamp
    autoload :Uuid
  end

  module Sections
    extend ActiveSupport::Autoload

    autoload :Delete
    autoload :Edit
    autoload :Export
    autoload :Index
    autoload :New
    autoload :Show
    autoload :Trash
  end
end

module MixAdmin
  class Engine < Rails::Engine
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
