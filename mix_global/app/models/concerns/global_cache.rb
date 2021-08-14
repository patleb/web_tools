# TODO config.active_record.cache_versioning
# TODO compare https://github.com/taxjar/persisted_cache
# TODO https://github.com/github/github-ds
module GlobalCache
  extend ActiveSupport::Concern

  # TODO missing some instance methods: #value, #mismatched?, #size, #compressed?
  # TODO compression
  class_methods do
    def exist?(name, **options)
      read_record(name, **options).present?
    end

    def fetch!(name, expires: false, **options, &block)
      fetch(name, expires: false, **options, &block)
    end

    def fetch(name, **options, &block)
      fetch_record(name, **options, &block)&.data
    end

    def fetch_multi!(*names, expires: false, **options, &block)
      fetch_multi(*names, expires: false, **options, &block)
    end

    def fetch_multi(*names, **options, &block)
      raise ArgumentError, "Missing block: Calling `Global#fetch_multi` requires a block." unless block_given?

      results = read_multi(*names, **options)
      (names.map{ |element| normalize_key(element) } - results.keys).each do |key|
        record = fetch_record(key, **options, &block)
        results[record.id] = record.data
      end
      results
    end

    def [](name)
      read(name)
    end

    def read(name, **options)
      read_record(name, **options)&.data
    end

    def read_multi(*names, **options)
      names = names.first if names.first.is_a? Regexp
      read_records(names, **options).transform_values!(&:data)
    end

    def []=(name, value)
      write! name, value
    end

    def write!(name, value, expires: false, **options)
      write(name, value, expires: false, **options)
    end

    def write(name, value, **options)
      write_record(name, value, **options)
      value
    end

    def write_multi!(hash, expires: false, **options)
      write_multi(hash, expires: false, **options)
    end

    def write_multi(hash, **options)
      hash.each_with_object({}.with_keyword_access) do |(name, value), memo|
        record = write_record(name, value, **options)
        memo[record.id] = value
      end
    end

    def increment!(*args, expires: false, **options)
      increment(*args, expires: false, **options)
    end

    def increment(name, amount = 1, **options)
      update_integer(name, amount, **options)
    end

    def decrement!(*args, expires: false, **options)
      decrement(*args, expires: false, **options)
    end

    def decrement(name, amount = 1, **options)
      update_integer(name, -amount, **options)
    end

    def delete(name, **)
      delete_record(name)
    end

    def delete_matched(matcher, **options)
      delete_records(matcher, **options)
    end

    def cleanup(**)
      expired.delete_all
    end

    def clear(**)
      expirable.delete_all
    end

    def clear!
      with_table_lock do
        connection.exec_query("TRUNCATE TABLE #{quoted_table_name}")
      end
    end
  end
end
