class NilClass
  def upcase_first
    ''
  end
end

class String
  OBJECT_INSPECT ||= /(#<)([^>]+)(>)/.freeze
  HEXADECIMAL ||= /0x[0-9a-f]+/i.freeze
  DECIMAL ||= /\d+([.,]\d+)*/.freeze

  def dehumanize
    parameterize(separator: '_')
  end

  def slugify
    parameterize.dasherize.downcase
  end

  def titlefy
    parameterize.humanize.squish.gsub(/([[:word:]]+)/u){ |word| word.downcase.capitalize }
  end

  def full_underscore(separator = '_')
    underscore.tr('/', separator).delete_prefix(separator).delete_suffix(separator)
  end

  def escape_inspect_delimiters(delimiters = '[]')
    gsub(OBJECT_INSPECT, "#{delimiters[0]}\\2#{delimiters[1]}")
  end

  def squish_numbers(placeholder = '0')
    gsub(SecureRandom::UUID, placeholder)
      .gsub(HEXADECIMAL, placeholder)
      .gsub(DECIMAL, placeholder)
  end

  def escape_regex
    Regexp.new(Regexp.escape(self)).source
  end

  def to_html_single_quotes
    gsub("'", '&#39;')
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
