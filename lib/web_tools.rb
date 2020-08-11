require 'ext_bootstrap'
require 'ext_capistrano'
# require 'ext_minitest'
require 'ext_pjax'
require 'ext_rake'
require 'ext_ruby'
require 'ext_vue'
require 'ext_webpacker'
# require 'ext_whenever'
# require 'mix_admin'
require 'mix_backup'
require 'mix_core'
require 'mix_global'
require 'mix_notifier'
# require 'mix_page'
require 'mix_rescue'
require 'mix_setting'
require 'mix_sql'
require 'mix_template'
require 'mix_throttler'
# require 'mix_user'
require 'sunzistrano'

module WebTools
  def self.gems
    @gems ||= root.children.select(&:directory?)
      .select{ |d| d.children.any? { |f| f.to_s.end_with? '.gemspec' } }
      .map(&:basename).map(&:to_s).map{ |d| [d, Gem.root(d)] }.to_h.with_indifferent_access
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__))
  end
end
