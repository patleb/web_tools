module Kernel
  def caller_location(start = 1)
    caller_locations(2, start)[start - 1]
  end

  def load_dir(*, **)
    require_or_load_dir(*, true, **)
  end

  def require_dir(*, **)
    require_or_load_dir(*, false, **)
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

  private

  def require_or_load_dir(location, dir = nil, _load = false, ext: 'rb', sort: false, reverse: false)
    files = Dir["#{File.dirname(location)}/#{dir}/**/*.#{ext}"]
    files = files.sort if sort
    files = files.reverse if reverse
    files.each do |file|
      _load ? load(file) : require(file)
    end
  end
end
