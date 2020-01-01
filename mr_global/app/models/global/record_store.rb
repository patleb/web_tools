# TODO compare
# https://github.com/taxjar/persisted_cache

module Global::RecordStore
  extend ActiveSupport::Concern

  included do
    include Global::RecordStore::Expiration
    include Global::RecordStore::Normalization

    self.postgres_exception_to_error = false
  end

  class_methods do
    def fetch_record(name, **options)
      options = options.reverse_merge expires: true
      if block_given?
        if options.delete(:force)
          write(name, yield, **options)
        else
          key = normalize_key(name)
          version = normalize_version(name, **options)
          if (record = where(id: key).take).nil?
            begin
              record = create! options.slice(:expires, :expires_in).merge!(id: key, version: version, data: yield)
              record.new!
            rescue ActiveRecord::RecordNotUnique
              record = where(id: key).take!
            end
          end
          if record._sync(version, &proc).destroyed?
            fetch_record(key, version: version, **options, &proc)
          end
          record
        end
      elsif options[:force]
        raise ArgumentError, "Missing block: Calling `Global#fetch_record` with `force: true` requires a block."
      else
        read_record(name, **options)
      end
    end

    ### Useful statements for the block:
    # - new record --> record.nil?
    # - skip write --> throw :skip_write
    # - rollback   --> throw :abort
    def write_record(name, value = nil, **options)
      options = options.reverse_merge expires: true
      block = block_given? ? proc : proc{ value }
      record = fetch_record(name, **options, &block)
      unless record.new?
        record.with_lock do
          version = normalize_version(name, **options)
          catch(:skip_write) do
            record.update! options.slice(:expires, :expires_in).merge!(version: version, data: block.call(record))
          end
        end
      end
      record
    rescue ActiveRecord::RecordNotFound
      # TODO test it (must not be inside a transaction block?)
      # https://dev.to/evilmartians/the-silence-of-the-ruby-exceptions-a-railspostgresql-database-transaction-thriller-5e30
      retry
    end

    def read_record(name, **options)
      key = normalize_key(name)
      if (record = where(id: key).take)
        version = normalize_version(name, **options)
        record unless record._sync_stale_state(version).stale?
      end
    end

    def read_records(names, **options)
      case names
      when Array
        keys = names.map{ |element| normalize_key(element) }
        where(id: keys).find_each.with_object({}).each do |record, memo|
          key = record.id
          version = normalize_version(names[keys.index(key)], **options)
          memo[key] = record unless record._sync_stale_state(version).stale?
        end
      when Regexp
        version = normalize_version(**options)
        where(column(:id) =~ key_matcher(names, **options)).find_each.with_object({}).each do |record, memo|
          memo[record.id] = record unless record._sync_stale_state(version).stale?
        end
      else
        raise ArgumentError, "Bad type: `Global#read_records` requires names as Array or Regexp."
      end
    end

    def delete_record(name)
      key = normalize_key(name)
      where(id: key).delete_all
    end

    def delete_records(matcher, **options)
      case matcher
      when Array  then matcher = GlobalKey.start_with(matcher)
      when Regexp then # do nothing
      else raise ArgumentError, "Bad type: `Global#delete_records` requires matcher as Array or Regexp."
      end
      where(column(:id) =~ key_matcher(matcher, **options)).delete_all
    end

    def update_integer(name, amount, **options)
      raise ArgumentError, "Bad type: `Global#update_integer` requires amount as Integer." unless amount.is_a? Integer

      options = options.reverse_merge expires: true
      key = normalize_key(name)
      if (result = update_counter(key, amount)).nil?
        version = normalize_version(name, **options)
        create! options.slice(:expires, :expires_in).merge!(id: key, version: version, data: amount)
        result = amount
      end
      result
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def update_counter(key, amount)
      raise ArgumentError, "Bad value: `Global#update_counter` requires amount != 0." if amount == 0

      operator = amount < 0 ? "-" : "+"
      quoted_column = connection.quote_column_name(:integer)
      updates = ["#{quoted_column} = COALESCE(#{quoted_column}, 0) #{operator} #{amount.abs}"]

      touch_updates = touch_attributes_with_time
      updates << sanitize_sql_for_assignment(touch_updates)

      unscoped.where(id: key).update_all(updates.join(", "), quoted_column)
    end
  end
end
