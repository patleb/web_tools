# frozen_string_literal: true

class Hash
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
    text = JSON.pretty_generate(self, indent: '  ', space: ' ', space_before: '', **options)
    case format
    when :html then ERB::Util.html_escape(text).sub(/\r?\n/, '').sub(' ', '').gsub(/\r?\n/, '<br>').gsub(' ', '&nbsp;').html_safe
    when :text then text.gsub(/\n/, "\r\n")
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
end
