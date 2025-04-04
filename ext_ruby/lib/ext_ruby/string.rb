if ENV['DEBUGGER_HOST']
  DEBUGGER_ENCODING = Encoding.find('ASCII-8BIT')

  module ActiveSupport::Inflector
    alias_method :translirerate_without_debugger, :transliterate
    def transliterate(string, *, **)
      string = string.force_encoding(Encoding::UTF_8) if string.encoding == DEBUGGER_ENCODING
      translirerate_without_debugger(string, *, **)
    end
  end
end

class NilClass
  def upcase_first
    self
  end

  def html_blank?
    true
  end
end

class Integer
  def to_bytes(*)
    self
  end
end

class String
  REPLACEMENT = ' '
  NIL_VALUE = /([(\[{,:] *)(nil)( *[,\]})])/
  NULL_VALUE = '\1null\3'
  HTML_BLANK = /(< *\/?p *\/?>|&nbsp;|< *br *\/?>)/
  OBJECT_INSPECT = /(#<)([^>]+)(>)/
  HEXADECIMAL = /0x[0-9a-f]+/i
  MD5_HEX = /[0-9a-f]{32}/i
  DECIMAL = /[-+]?(\d+(\.\d+)*(e[-+]?\d+)?|infinity)/i
  UUID = /[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}/i
  BYTES = {
    'BYTE' => 1,  'BYTES' => 1,  'KB' => 1024, 'MB' => 1024**2, 'GB' => 1024**3, 'TB' => 1024**4, 'PB' => 1024**5,
    'OCTET' => 1, 'OCTETS' => 1, 'KO' => 1024, 'MO' => 1024**2, 'GO' => 1024**3, 'TO' => 1024**4, 'PO' => 1024**5,
  }
  DB_BYTES = {
    'BYTE' => 1,  'BYTES' => 1,  'KB' => 1024, 'MB' => 1000*1024, 'GB' => 1000*1024**2, 'TB' => 1000*1024**3, 'PB' => 1000*1024**4,
    'OCTET' => 1, 'OCTETS' => 1, 'KO' => 1024, 'MO' => 1000*1024, 'GO' => 1000*1024**2, 'TO' => 1000*1024**3, 'PO' => 1000*1024**4,
  }

  def to_bytes(standard = nil)
    value, units = upcase.split
    value = value.tr(',', '.') if BYTES.has_key?(units) && units.include?('O')
    (value.cast_self * (standard == :db ? DB_BYTES[units] : BYTES[units])).to_i
  end

  def to_args
    args = gsub(NIL_VALUE, NULL_VALUE).gsub(NIL_VALUE, NULL_VALUE)
    YAML.safe_load args
  end

  def to_rgb
    return unless match? /\A#[0-9a-f]{6}\z/i
    rgb = []
    chars[1..-1].each_slice(2) do |chars|
      rgb << chars.join.to_i(16)
    end
    rgb
  end

  def match_glob?(pattern)
    if pattern.include? '*'
      match? Regexp.new("^#{pattern.gsub('*', '\w*')}$")
    else
      self == pattern
    end
  end

  def html_blank?
    gsub(HTML_BLANK, '').blank?
  end

  def quoted
    self[0] == ?" && self[-1] == ?" ? self : %{"#{self}"}
  end

  def transliterate(locale = :en, replacement = REPLACEMENT)
    ActiveSupport::Inflector.transliterate(self, replacement, locale: locale)
  end

  # Convert to Base36 + space separators
  def simplify(locale = :en)
    string = transliterate(locale)
    string.gsub! /[^A-Za-z0-9 ]+/, ' '
    string.squish!
    string.downcase!
    string
  end

  def trigrams(locale = :en)
    simplify(locale).split.each_with_object(SortedSet.new) do |word, result|
      "  #{word} ".chars.each_cons(3).map do |chars|
        result << chars.join
      end
    end
  end

  def similarity(other, locale = :en)
    left = trigrams(locale)
    right = other.trigrams(locale)
    return 0.0 if left.empty? && right.empty?
    (left & right).size / (left | right).size.to_f
  end

  def dehumanize
    parameterize(separator: '_')
  end

  def slugify
    parameterize.dasherize
  end

  def full_underscore(separator = '_')
    underscore.tr('/', separator).delete_prefix(separator).delete_suffix(separator)
  end

  def escape_inspect_delimiters(delimiters = '[]')
    gsub(OBJECT_INSPECT, "#{delimiters[0]}\\2#{delimiters[1]}")
  end

  def squish_all(max_length = nil)
    string = squish_numbers.squish!
    string = string[0...max_length] if max_length
    string
  end

  def squish_numbers(placeholder = '*')
    string = gsub(UUID, placeholder)
    string.gsub!(HEXADECIMAL, placeholder)
    string.gsub!(MD5_HEX, placeholder)
    string.gsub!(DECIMAL, placeholder)
    string
  end

  def squish_char(char, prefix: nil, suffix: nil, both: nil)
    string = gsub(/#{char}{2,}/, char)
    string.delete_prefix! char if prefix || both
    string.delete_suffix! char if suffix || both
    string
  end

  def escape_regex
    Regexp.new(Regexp.escape(self)).source
  end

  def to_html_single_quotes
    gsub("'", '&#39;')
  end

  def escape_single_quotes(type = :ascii)
    case type
    when :ascii then gsub(/'/, '\\x27')
    when :shell then gsub(/'/){ "'\\''" }
    when :char  then gsub(/'/){ "\\'" }
    end
  end

  def unescape_single_quotes(type = :ascii)
    case type
    when :ascii then gsub('\\x27', "'")
    when :shell then gsub("'\\''", "'")
    when :char  then gsub("\\'", "'")
    end
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
    return if n < 1
    to_enum(:scan, match).find.with_index(1){ |_, i| n == i } ? Regexp.last_match.begin(0) : nil
  end

  def index_all(match, n = 1)
    return [] if n < 1
    indexes = to_enum(:scan, match).map{ Regexp.last_match.begin(0) }
    indexes = indexes[(n - 1)..-1] if n > 1
    indexes
  end
end
