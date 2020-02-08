class Rescue < LibRecord
  with_options presence: true do
    validates :exception
    validates :message
  end

  def self.enqueue(exception, message = exception.message)
    create!(
      type: sti_name,
      exception: exception.name,
      message: message,
      data: exception.data
    )
  end

  def self.dequeue(exception)
    super(inheritance_column, :exception, :created_at) do |quoted_type, quoted_exception, quoted_created_at|
      <<-SQL
        WHERE #{quoted_type} = '#{sti_name}'
        AND #{quoted_exception} = '#{exception}'
        ORDER BY #{quoted_created_at}
      SQL
    end
  end
end
