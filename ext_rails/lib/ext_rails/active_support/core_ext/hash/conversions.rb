class Hash
  alias_method :attributes, :to_hash
  alias_method :attribute_names, :keys

  def attributes_hash
    to_hash.to_hwka
  end
end
