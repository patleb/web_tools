class Global < LibRecord
  include self::CacheStore

  # TODO add :type to be able to differentiate between Cache usage and others --> and maybe set expirable to true
  # enum type: {
  #   'Global' => 0,
  #   'GlobalCache' => 1
  # }

  enum data_type: {
    text:       0,
    json:       10,
    boolean:    20,
    integer:    30,
    decimal:    40,
    datetime:   50,
    interval:   60,
    serialized: 70,
  }

  attribute :data

  after_initialize :set_data

  def data=(data)
    if (new_type = type_of(data)) != data_type
      self[data_type] = nil
      self.data_type = new_type
    end
    if new_type == 'serialized'
      self[data_type] = Marshal.dump(data)
      self[:data] = data
    else
      self[:data] = self[data_type] = cast(data)
    end
  end

  private

  def type_of(data)
    case data
    when Array, Hash             then 'json'
    when Boolean                 then 'boolean'
    when Integer                 then 'integer'
    when Float, BigDecimal       then 'decimal'
    when Date, Time, DateTime    then 'datetime'
    when ActiveSupport::Duration then 'interval'
    when String, Symbol, nil     then 'text'
    else                              'serialized'
    end
  end

  def set_data
    self[:data] = cast(self[data_type])
    clear_attribute_changes [:data]
  end

  def cast(data)
    return data unless data

    case data_type
    when 'json'
      if data.is_a? Array
        data.map!{ |item| item.is_a?(Hash) ? item.with_indifferent_access : item }
      else
        data.with_indifferent_access
      end
    when 'serialized'
      Marshal.load(data) rescue data
    else
      data
    end
  end
end
