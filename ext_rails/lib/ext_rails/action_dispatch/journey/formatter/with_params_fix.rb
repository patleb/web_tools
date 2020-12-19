ActionDispatch::Journey::Formatter.class_eval do
  private

  # TODO add tool to check if source code has changed compared to the one that was used at the time
  def extract_parameterized_parts(route, options, recall, parameterize = nil)
    parameterized_parts = recall.merge(options)

    keys_to_keep = route.parts.reverse_each.drop_while { |part|
      !(options.key?(part) || route.scope_options.key?(part)) || (options[part] || recall[part]).nil?
    } | route.required_parts

    parameterized_parts.delete_if do |bad_key, _|
      # TODO Rails 6.1 update/open issue (iterator on hash with indifferent access expose string keys)
      !keys_to_keep.include?(bad_key.to_sym)
    end

    if parameterize
      parameterized_parts.each do |k, v|
        parameterized_parts[k] = parameterize.call(k, v)
      end
    end

    parameterized_parts.keep_if { |_, v| v }
    parameterized_parts
  end
end
