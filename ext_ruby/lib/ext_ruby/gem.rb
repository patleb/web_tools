module Gem
  def self.root(name)
    if (spec = Gem.loaded_specs[name])
      Pathname.new(spec.gem_dir)
    end
  end

  def self.exists?(name)
    Gem.loaded_specs.has_key? name
  end
end
