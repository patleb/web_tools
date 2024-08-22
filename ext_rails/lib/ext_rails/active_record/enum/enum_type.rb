MonkeyPatch.add{['activerecord', 'lib/active_record/enum.rb', '3822404e7b275407cb12c8a2a5719f4a0d12260dc059f471d304f9faaf702cb9']}

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
