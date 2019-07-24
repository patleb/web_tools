module Global::RecordStore::Normalization
  extend ActiveSupport::Concern

  class_methods do
    private

    def normalize_key(key, **)
      # no namespace functionality implemented on purpose --> https://github.com/kickstarter/rack-attack/issues/370
      expanded_key(key).tr('/', GlobalKey::SEPARATOR)
    end

    def expanded_key(key)
      return key.cache_key.to_s if key.respond_to? :cache_key

      case key
      when Array
        key = (key.size > 1) ? key.map{ |element| expanded_key(element) } : key.first
      when Hash
        key = key.sort_by{ |k, _| k.to_s }.map{ |k, v| "#{k}=#{v}" }
      end

      key.to_param
    end

    def normalize_version(key = nil, version: nil, **)
      (version&.to_param || expanded_version(key || '')).presence
    end

    def expanded_version(key)
      case
      when key.respond_to?(:cache_version) then key.cache_version.to_param
      when key.is_a?(Array)                then key.map{ |element| expanded_version(element) }.compact.to_param
      when key.respond_to?(:to_a)          then expanded_version(key.to_a)
      end
    end

    def key_matcher(pattern, **)
      regex = pattern.source.tr('/', GlobalKey::SEPARATOR)
      if !regex.start_with?('^') || regex.in?(['', '^', '$']) || regex.exclude?(GlobalKey::SEPARATOR)
        raise ArgumentError, "Bad value: `Global#key_matcher` pattern /#{regex}/ matches too much."
      end
      sanitize_matcher /#{regex}/
    end
  end
end
