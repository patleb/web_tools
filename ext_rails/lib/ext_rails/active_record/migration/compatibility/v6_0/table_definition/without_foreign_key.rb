module ActiveRecord::Migration::Compatibility::V6_0::TableDefinition::WithoutForeignKey
  def belongs_to(*args, **options)
    return super unless Rails.env.test?
    options = options.merge(foreign_key: false)
    super(*args, **options)
  end
end

ActiveRecord::Migration::Compatibility::V6_0::TableDefinition.prepend ActiveRecord::Migration::Compatibility::V6_0::TableDefinition::WithoutForeignKey
