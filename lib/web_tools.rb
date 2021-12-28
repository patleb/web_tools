require 'web_tools/base'

module WebTools
  def self.private_gems
    @private_gems ||= (!File.exists?('Gemfile.private') ? [] : File.readlines('Gemfile.private')
      .select_map{ |line| line.match(/(?:^| +)gem +["']([^"']+)["']/)&.captures&.first })
      .flat_map{ |name| tools Gem.root(name) }
      .map{ |d| [d, Gem.root(d)] }
      .to_h.with_indifferent_access
  end

  def self.gems
    @gems ||= tools(root)
      .map{ |d| [d, Gem.root(d)] }
      .to_h.with_indifferent_access
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__))
  end

  def self.tools(root)
    root.children.select{ |d| d.directory? && d.children.any?{ |f| f.to_s.end_with? '.gemspec' } }.map{ |d| d.basename.to_s }
  end
  private_class_method :tools
end
