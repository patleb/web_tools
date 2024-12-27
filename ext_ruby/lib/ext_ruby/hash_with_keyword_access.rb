if defined? Rails.env
  MonkeyPatch.add{['activesupport', 'lib/active_support/hash_with_indifferent_access.rb', 'd8bed338cef6949309cb6f1ac4bcc79f88f3a892ed9c5961ea8a4cc2470eab23']}
  MonkeyPatch.add{['activesupport', 'lib/active_support/core_ext/hash/indifferent_access.rb', '2165533368d0f6a03c47e1e8d8f5df95777ae2685bbdba9c00e3d097f41bd8ff']}
end

  # NOTE
# (hash_with_keyword_access[key] ||= {})
# if not assigned already, it returns {} instead of the converted one
# so, either use (hash_with_keyword_access[key] ||= {}.to_hwka)
# or use (hash[key] ||= {}) and convert the root node after assignments
class HashWithKeywordAccess < Hash
  def self.convert_key(key)
    # key.is_a?(String) && key.match?(Hash::KEYWORD) ? key.to_sym : key
    key.is_a?(String) ? key.to_sym : key
  end

  def extractable_options?
    true
  end

  def with_keyword_access
    dup
  end

  def nested_under_keyword_access
    self
  end

  def initialize(constructor = nil)
    if constructor.respond_to?(:to_hash)
      super()
      update(constructor)

      hash = constructor.is_a?(Hash) ? constructor : constructor.to_hash
      self.default = hash.default if hash.default
      self.default_proc = hash.default_proc if hash.default_proc
    elsif constructor.nil?
      super()
    else
      super(constructor)
    end
  end

  def self.[](*args)
    new.merge!(Hash[*args])
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  def []=(key, value)
    regular_writer(convert_key(key), convert_value(value, conversion: :assignment))
  end

  alias_method :store, :[]=

  def update(*other_hashes, &block)
    if other_hashes.size == 1
      update_with_single_argument(other_hashes.first, block)
    else
      other_hashes.each do |other_hash|
        update_with_single_argument(other_hash, block)
      end
    end
    self
  end

  alias_method :merge!, :update

  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  def [](key)
    super(convert_key(key))
  end

  def assoc(key)
    super(convert_key(key))
  end

  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  def dig(*args)
    args[0] = convert_key(args[0]) if args.size > 0
    super(*args)
  end

  def default(key = (no_key = true))
    if no_key
      super()
    else
      super(convert_key(key))
    end
  end

  def values_at(*keys)
    keys.map! { |key| convert_key(key) }
    super
  end

  def fetch_values(*indices, &block)
    indices.map! { |key| convert_key(key) }
    super
  end

  def dup
    self.class.new(self).tap do |new_hash|
      set_defaults(new_hash)
    end
  end

  def merge(*hashes, &block)
    dup.update(*hashes, &block)
  end

  def reverse_merge(other_hash)
    super(self.class.new(other_hash))
  end
  alias_method :with_defaults, :reverse_merge

  def reverse_merge!(other_hash)
    super(self.class.new(other_hash))
  end
  alias_method :with_defaults!, :reverse_merge!

  def replace(other_hash)
    super(self.class.new(other_hash))
  end

  # Removes the specified key from the hash.
  def delete(key)
    super(convert_key(key))
  end

  def except(*keys)
    dup.except!(*keys)
  end
  alias_method :without, :except

  undef :stringify_keys!
  undef :deep_stringify_keys!
  def stringify_keys; to_hash.stringify_keys! end
  def deep_stringify_keys; to_hash.deep_stringify_keys! end
  def symbolize_keys!; self end
  def deep_symbolize_keys!; self end
  def symbolize_keys; dup end
  alias_method :to_options, :symbolize_keys
  def deep_symbolize_keys; dup end
  def to_options!; self end

  def select(*args, &block)
    return to_enum(:select) unless block_given?
    dup.tap { |hash| hash.select!(*args, &block) }
  end

  def reject(*args, &block)
    return to_enum(:reject) unless block_given?
    dup.tap { |hash| hash.reject!(*args, &block) }
  end

  def transform_values(&block)
    return to_enum(:transform_values) unless block_given?
    dup.tap { |hash| hash.transform_values!(&block) }
  end

  NOT_GIVEN = Object.new # :nodoc:

  def transform_keys(hash = NOT_GIVEN, &block)
    return to_enum(:transform_keys) if NOT_GIVEN.equal?(hash) && !block_given?
    dup.tap { |h| h.transform_keys!(hash, &block) }
  end

  def transform_keys!(hash = NOT_GIVEN, &block)
    return to_enum(:transform_keys!) if NOT_GIVEN.equal?(hash) && !block_given?

    if hash.nil?
      super
    elsif NOT_GIVEN.equal?(hash)
      keys.each { |key| self[yield(key)] = delete(key) }
    elsif block_given?
      keys.each { |key| self[hash[key] || yield(key)] = delete(key) }
    else
      keys.each { |key| self[hash[key] || key] = delete(key) }
    end

    self
  end

  def slice(*keys)
    keys.map! { |key| convert_key(key) }
    self.class.new(super)
  end

  def slice!(*keys)
    keys.map! { |key| convert_key(key) }
    super
  end

  def compact
    dup.tap(&:compact!)
  end

  def to_hash
    _new_hash = Hash.new
    set_defaults(_new_hash)

    each do |key, value|
      _new_hash[key] = convert_value(value, conversion: :to_hash)
    end
    _new_hash
  end

  private

  def convert_key(key)
    self.class.convert_key(key)
  end

  def convert_value(value, conversion: nil)
    if value.is_a? Hash
      if conversion == :to_hash
        value.to_hash
      else
        value.nested_under_keyword_access
      end
    elsif value.is_a?(Array)
      if conversion != :assignment || value.frozen?
        value = value.dup
      end
      value.map! { |e| convert_value(e, conversion: conversion) }
    else
      value
    end
  end

  def set_defaults(target)
    if default_proc
      target.default_proc = default_proc.dup
    else
      target.default = default
    end
  end

  def update_with_single_argument(other_hash, block)
    if other_hash.is_a? HashWithKeywordAccess
      regular_update(other_hash, &block)
    else
      other_hash.to_hash.each_pair do |key, value|
        if block && key?(key)
          value = block.call(convert_key(key), self[key], value)
        end
        regular_writer(convert_key(key), convert_value(value))
      end
    end
  end
end

class Hash
  alias_method :to_hwia, :with_indifferent_access

  def with_keyword_access
    HashWithKeywordAccess.new(self)
  end
  alias_method :to_hwka, :with_keyword_access

  alias nested_under_keyword_access with_keyword_access
end
