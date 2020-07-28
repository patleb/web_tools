class Module
  def autoload_dir(base_dir)
    Dir[Pathname.new(base_dir).expand_path.join('*.rb')].each do |file|
      type_name = File.basename(file).delete_suffix('.rb').camelize.to_sym
      autoload type_name, file
    end
  end
end
