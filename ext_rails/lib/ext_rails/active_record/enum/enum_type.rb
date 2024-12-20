MonkeyPatch.add{['activerecord', 'lib/active_record/enum.rb', '3116192d0cdb70dc574b359a4d54a8080d8183226b1fb3910e45b2d6512fe1aa']}

ActiveRecord::Enum::EnumType.class_eval do
  def cast(value)
    if mapping.has_key?(value)
      ActiveSupport::HashWithIndifferentAccess.convert_key(value)
    elsif mapping.has_value?(value)
      mapping.key(value)
    else
      value.presence
    end
  end
end
