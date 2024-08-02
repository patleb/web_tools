class String
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

  def compile_sql(delimiters = '[]', **variables)
    open, close = delimiters.chars
    open_regex, close_regex = open.escape_regex, close.escape_regex
    result = strip_sql(**variables)
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

  def strip_tags
    Nokogiri::HTML(self).text
  end
end
