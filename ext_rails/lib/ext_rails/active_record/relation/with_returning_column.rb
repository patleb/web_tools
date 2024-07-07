module ActiveRecord::Relation::WithReturningColumn
  def update_all(updates, column = nil)
    return super(updates) unless column
    klass.connection.with(returning: column) do
      super(updates)
    end
  end
end
