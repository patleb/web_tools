class ERB
  def self.template(src, binding = nil)
    erb = ERB.new(Pathname.new(src).read)
    binding ? erb.result(binding) : erb.result
  end
end
