module ActiveRecord::Base::WithRescuableValidations
  RECORD_NOT_UNIQUE_COLUMN = /Key \((["\w\s,]+)\)=\(.*?\) already exists/.freeze
  INVALID_FOREIGN_KEY_COLUMN = /Key \((["\w\s,]+)\)=\(.*?\) is not present in table/.freeze
  VALUE_TOO_LONG_COUNT = /varying\((?<count>\d+)\)/.freeze
  NOT_NULL_VIOLATION_COLUMN = /column "(\w+)"(?: of relation "\w+")? violates not-null constraint/.freeze

  def save(...)
    super
  rescue ActiveRecord::RecordNotUnique => e
    _handle_columns_exception(e, RECORD_NOT_UNIQUE_COLUMN, :taken)
  rescue ActiveRecord::InvalidForeignKey => e
    _handle_columns_exception(e, INVALID_FOREIGN_KEY_COLUMN, :required)
  rescue ActiveRecord::ValueTooLong => e
    _handle_base_exception(e, VALUE_TOO_LONG_COUNT, :too_long, &:to_i)
    # rescue ActiveModel::RangeError => e
  rescue ActiveRecord::NotNullViolation => e
    _handle_columns_exception(e, NOT_NULL_VIOLATION_COLUMN, :blank)
    # rescue ActiveRecord::SerializationFailure => e
    # rescue ActiveRecord::Deadlocked => e
    # rescue ActiveRecord::LockWaitTimeout => e
    # rescue ActiveRecord::QueryCanceled => e
  end

  private

  def _handle_columns_exception(exception, columns_regex, error_type)
    columns = exception.message[columns_regex, 1]
    columns.split(',').map{ |column| column.gsub('"', '').split('.').last.strip }.each do |column|
      errors.add column.to_sym, error_type
    end
    false
  end

  def _handle_base_exception(exception, values_regex, error_type, &block)
    values = exception.message.match(values_regex).named_captures
    values = values.transform_values(&block) if block_given?
    errors.add :base, error_type, **values.with_indifferent_access
    false
  end
end
