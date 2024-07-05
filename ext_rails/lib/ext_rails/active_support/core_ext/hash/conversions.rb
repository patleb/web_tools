class Hash
  alias_method :attributes, :to_hash
  alias_method :attribute_names, :keys

  def attributes!
    to_hash.with_indifferent_access
  end

  def attribute_names!
    attributes!.keys
  end
end
