DUMMY_GEMS = Set.new(%w(
  1st_gem
  2nd_gem
  3rd_gem
))

module Gem
  def self.root(name)
    if DUMMY_GEMS.include? name
      $test.root.join('gems', name)
    elsif (spec = Gem.loaded_specs[name])
      Pathname.new(spec.gem_dir)
    end
  end
end
