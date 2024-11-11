require 'mix_admin/configuration'
require 'mix_admin/routes'

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
    autoload :Trash
  end

  module Fields
    extend ActiveSupport::Autoload

    autoload :Association
    autoload :BelongsTo
    autoload :BelongsToListParent
    autoload :BelongsToPolymorphic
    autoload :Boolean
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
    autoload :Restore
    autoload :Show
    autoload :Trash
  end
end

module MixAdmin
  class Engine < ::Rails::Engine
    require 'mix_global'
    require 'mix_user'
    require 'mix_admin/active_support/core_ext/numeric/conversions'
    require 'mix_admin/active_support/core_ext/object/full_symbolize'
    require 'mix_admin/active_support/core_ext/string'

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
