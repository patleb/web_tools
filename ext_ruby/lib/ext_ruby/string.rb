class String
  def escape_regex
    Regexp.new(Regexp.escape(self)).source
  end

  def escape_single_quotes
    gsub(/'/, '\\x27')
  end

  def unescape_single_quotes
    gsub('\\x27', "'")
  end

  def escape_newlines
    gsub(/\r?\n/, "\\\\n")
  end

  def unescape_newlines
    gsub(/\\n/, "\n")
  end

  def partition_at(truncate_at, separator: nil, fallback: nil)
    return [self, ''] unless size > truncate_at

    if separator
      before_at = rindex(separator, truncate_at)
      if !before_at && fallback && (fallback != separator)
        before_at = rindex(fallback, truncate_at)
      end
      truncate_at = before_at || truncate_at
    end
    [self[0, truncate_at], self[truncate_at..-1]]
  end

  def index_n(match, n = 1)
    to_enum(:scan, match).find.with_index(1){ |_, i| n == i } ? Regexp.last_match.begin(0) : nil
  end

  def index_all(match, n = 1)
    return if n < 1
    indexes = to_enum(:scan, match).map{ Regexp.last_match.begin(0) }
    indexes = indexes[(n - 1)..-1] if n > 1
    indexes
  end
end
