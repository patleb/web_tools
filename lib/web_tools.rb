require 'web_tools/base'

module WebTools
  def self.gems
    @gems ||= root.children.select(&:directory?)
      .select{ |d| d.children.any? { |f| f.to_s.end_with? '.gemspec' } }
      .map(&:basename).map(&:to_s)
      .reject{ |name| name == 'mix_backup' }
      .map{ |d| [d, Gem.root(d)] }
      .to_h.with_indifferent_access
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__))
  end
end
