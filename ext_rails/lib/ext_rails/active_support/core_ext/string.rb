class String
  include DateAndTime::Conversions

  def sql_safe
    Arel.sql(self)
  end

  def strip_sql(**variables)
    result = strip.gsub(/(--.*\n|\n)/, ' ').gsub(/\s{2,}/, ' ')
    unless variables.empty?
      result = variables.reduce(result) do |sql, (name, value)|
        sql.gsub(/\{\{\s*#{name}\s*\}\}/, value.to_s.strip_sql)
      end
    end
    result
  end

  def compile_sql(**variables)
    result = strip_sql(**variables)
    result.gsub! "'", "''"
    result.start_with?('[') ? result.delete_prefix!('[') : result.prepend("'")
    result.end_with?(']') ? result.delete_suffix!(']') : result.concat("'")
    result.gsub! /\]\s*\[/, ' '
    result.gsub! /\[/, "'["
    result.gsub! /\]/, "]'"
    result = result.split(/[\[\]]/).join(' || ')
    result.gsub! /\s*' \|\| (INTO|USING) /i, "' \\1 "
    result
  end
end
