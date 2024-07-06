module ActiveRecord::ConnectionAdapters::TableDefinition::WithoutForeignKey
  def belongs_to(*args, **options)
    return super unless Rails.env.test?
    options = options.merge(foreign_key: false)
    super(*args, **options)
  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.prepend ActiveRecord::ConnectionAdapters::TableDefinition::WithoutForeignKey
