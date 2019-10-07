class Hash
  alias_method :attributes, :to_hash

  def pretty_json
    JSON.pretty_generate(self, indent: '  ', space: ' ', space_before: '')
  end
end
