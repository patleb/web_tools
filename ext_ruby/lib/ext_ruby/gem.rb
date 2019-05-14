module Gem
  def self.root(name)
    if (spec = Gem.loaded_specs[name])
      Pathname.new(spec.gem_dir)
    end
  end
end
