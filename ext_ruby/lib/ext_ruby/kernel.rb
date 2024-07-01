module Kernel
  def caller_location(start = 1)
    caller_locations(2, start)[start - 1]
  end

  def load_dir(location, dir = nil, ext: 'rb')
    Dir["#{File.dirname(location)}/#{dir}/**/*.#{ext}"].sort.each do |file|
      load file
    end
  end

  def require_dir(location, dir = nil, ext: 'rb')
    Dir["#{File.dirname(location)}/#{dir}/**/*.#{ext}"].sort.each do |file|
      require file
    end
  end

  def require_and_extend(location, context)
    Dir["#{File.dirname(location)}/#{context.name.underscore}/**/*.rb"].sort.each do |file|
      require file
      name = File.basename(file, '.rb')
      context.extend const_get(name.camelize)
    end
  end

  def __super__(name, *args, **options, &block)
    method(name).super_method&.call(*args, **options, &block)
  end
end
