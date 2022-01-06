class String
  include DateAndTime::Conversions

  def sql_safe
    Arel.sql(self)
  end

  def strip_sql(**variables)
    result = strip.gsub(/(--.*\n|\n)/, ' ').gsub(/\s{2,}/, ' ')
    unless variables.empty?
      result = variables.reduce(result) do |result, (name, value)|
        result.gsub(/\{\{\s*#{name}\s*\}\}/, value.to_s.strip_sql)
      end
    end
    result
  end

  def compile_sql(delimiters = '[]')
    open, close = delimiters.chars
    open_regex, close_regex = open.escape_regex, close.escape_regex
    result = strip_sql
    result.gsub! "'", "''"
    result.start_with?(open) ? result.delete_prefix!(open) : result.prepend("'")
    result.end_with?(close) ? result.delete_suffix!(close) : result.concat("'")
    result.gsub! /#{close_regex}\s*#{open_regex}/, ' '
    result.gsub! /#{open_regex}/, "'#{open}"
    result.gsub! /#{close_regex}/, "#{close}'"
    result = result.split(/[#{open_regex}#{close_regex}]/).join(' || ')
    result.gsub! /\s*' \|\| (INTO|USING) /i, "' \\1 "
    result
  end
end
