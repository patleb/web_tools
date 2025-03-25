module Kernel
  def caller_location(start = 1)
    caller_locations(2, start)[start - 1]
  end

  def load_dir(*, **)
    require_or_load_dir(*, _load: true, **)
  end

  def require_dir(*, **)
    require_or_load_dir(*, _load: false, **)
  end

  def require_and_extend(location, context, nest: true, sort: false, reverse: false)
    files_for "#{File.dirname(location)}/#{context.name.underscore}#{'/**' if nest}/*.rb", sort, reverse do |file|
      require file
      name = File.basename(file, '.rb')
      context.extend const_get(name.camelize)
    end
  end

  def __super__(name, ...)
    method(name).super_method.call(...)
  end

  def __call__(name, instance, ...)
    instance_method(name).bind(instance).call(...)
  end

  private

  def require_or_load_dir(location, dir = nil, _load: false, ext: 'rb', nest: true, sort: false, reverse: false)
    files_for "#{File.dirname(location)}#{"/#{dir}" if dir}#{'/**' if nest}/*.#{ext}", sort, reverse do |file|
      _load ? load(file) : require(file)
    end
  end

  def files_for(path, sort, reverse)
    files = Dir[path]
    files = files.sort if sort
    files = files.reverse if reverse
    return files unless block_given?
    files.each do |file|
      yield file
    end
  end
end
