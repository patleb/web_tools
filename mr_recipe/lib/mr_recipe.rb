require 'ext_rake'
require 'mr_recipe/sh'

module MrRecipe
  require 'mr_recipe/railtie' if defined? Rails

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
