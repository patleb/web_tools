class Hash
  INTEGER = /^\d+$/

  def self.deep_union(*)
    union(*, deep: true)
  end

  def self.union(_key, old_value, new_value, deep: false)
    if old_value.is_a?(Array) && new_value.is_a?(Array)
      old_value | new_value
    elsif old_value.is_a?(Hash) && new_value.is_a?(Hash)
      deep ? old_value.union(new_value, deep: true) : old_value.merge(new_value)
    else
      new_value
    end
  end

  def deep_union(*)
    union(*, deep: true)
  end

  def deep_union!(*)
    union!(*, deep: true)
  end

  def union!(*, deep: false)
    merge!(*, &self.class.method(deep ? :deep_union : :union))
  end

  def union(*, deep: false)
    merge(*, &self.class.method(deep ? :deep_union : :union))
  end

  def pretty_json(format = nil, **options)
    text = JSON.pretty_generate(self, indent: '  ', space: ' ', space_before: '', depth: 1, **options)
    case format
    when :text then text.gsub(/\n/, "\r\n")
    when :html then ERB::Util.html_escape(text)
      .sub(/\r?\n/, '')    # remove first new line
      .sub(' ', '')        # remove first space
      .sub(/^ {2}}$/, '}') # remove last closing indent
      .gsub(/\r?\n/, '<br>')
      .gsub(' ', '&nbsp;').html_safe
    else text
    end
  end

  def pretty_hash!
    pretty_hash(true)
  end

  def pretty_hash(sort = nil)
    return unless present?
    hash = self
    hash = hash.sort_by{ |k, _| k.to_s }.to_h if sort
    hash.cast_self.to_s.gsub(/:(\w+)=>/, '\1: ')
  end

  def pretty_yaml(**options)
    to_yaml(line_width: -1, **options).delete_prefix("---\n").delete_prefix("--- {}\n")
  end

  def nest_keys
    each_with_object({}) do |(key, value), root|
      undig_key(root, key.split('.'), value)
    end
  end

  private

  def undig_key(node, keys, value)
    return if keys.empty?
    key, *remaining = keys
    key = key.to_i if key.match? INTEGER
    return node[key] = value if remaining.empty?
    node[key] ||= remaining.first.match?(INTEGER) ? [] : {}
    undig_key(node[key], remaining, value)
  end
end
