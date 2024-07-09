class Hash
  alias_method :attributes, :to_hash
  alias_method :attribute_names, :keys

  def attributes_hash
    to_hash.with_indifferent_access
  end

  def attribute_keys
    attributes_hash.keys
  end
end
