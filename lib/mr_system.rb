module MrSystem
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
