require 'whenever'
require 'mix_setting'
require 'sunzistrano'

module ExtWhenever
  def self.setup(context)
    path = root.join('lib/ext_whenever/setup.rb')
    context.instance_eval(path.read, path.to_s)
  end

  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
