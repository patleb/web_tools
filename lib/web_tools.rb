require 'ext_coffee'
require 'ext_css'
# require 'ext_minitest'
require 'ext_rails'
require 'ext_ruby'
# require 'ext_shakapacker'
# require 'ext_whenever'
require 'mix_admin'
require 'mix_certificate'
require 'mix_file'
require 'mix_flash'
require 'mix_geo'
require 'mix_global'
require 'mix_job'
require 'mix_page'
require 'mix_rpc'
require 'mix_search'
require 'mix_server'
require 'mix_setting'
require 'mix_task'
require 'mix_user'
require 'sunzistrano'

module WebTools
  def self.isolated_test_gems
    @isolated_test_gems ||= Set.new(['mix_geo', 'mix_task'])
  end

  def self.private_gems
    @private_gems ||= (!File.exist?('Gemfile.private') ? [] : File.readlines('Gemfile.private')
      .select_map{ |line| line.match(/^ *gem +["']([^"']+)["']/)&.captures&.first })
      .flat_map{ |name| subgems Gem.root(name) }
      .index_with{ |d| Gem.root(d) }
      .to_hwia
  end

  def self.gems
    @gems ||= subgems(root)
      .index_with{ |d| Gem.root(d) }
      .to_hwia
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__))
  end

  def self.subgems(root)
    list = root.children.select do |d|
      d.directory? && d.children.any?{ |f| f.to_s.end_with? '.gemspec' }
    end
    list.any? ? list.map{ |d| d.basename.to_s } : [root.basename.to_s]
  end
  private_class_method :subgems
end
