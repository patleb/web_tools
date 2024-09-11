require 'mix_admin/engine'

module MixAdmin
  # Your code goes here...
end

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
    autoload :Export
    autoload :Index
    autoload :New
    autoload :Show
    autoload :Trash
  end

  module Fields
    extend ActiveSupport::Autoload

    autoload :BelongsTo
    autoload :BelongsToListParent
    autoload :BelongsToPolymorphic
    autoload :Boolean
    autoload :BooleanArray
    autoload :Code
    autoload :Date
    autoload :DateArray
    autoload :DateTime
    autoload :DateTimeArray
    autoload :Decimal
    autoload :DecimalArray
    autoload :Discarded
    autoload :Enum
    autoload :EnumArray
    autoload :EnumAttribute
    autoload :EnumSti
    autoload :ForeignKey
    autoload :HasMany
    autoload :HasOne
    autoload :Hidden
    autoload :Hstore
    autoload :Integer
    autoload :IntegerArray
    autoload :Interval
    autoload :IntervalArray
    autoload :Json
    autoload :JsonArray
    autoload :Money
    autoload :Password
    autoload :Serialized
    autoload :String
    autoload :StringArray
    autoload :Text
    autoload :Time
    autoload :TimeArray
    autoload :Timestamp
    autoload :TimestampArray
    autoload :Uuid
  end

  module Sections
    extend ActiveSupport::Autoload

    autoload :Delete
    autoload :Edit
    autoload :Export
    autoload :Index
    autoload :Nested
    autoload :New
    autoload :Show
  end
end
