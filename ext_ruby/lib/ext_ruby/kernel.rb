module Kernel
  # TODO 2.6 Binding#source_location
  def caller_location(start = 1)
    caller_locations(2, start)[start - 1]
  end

  def require_and_extend(location, context)
    Dir[File.join(File.expand_path(File.dirname(location)), "#{context.name.underscore}/**/*.rb")].each do |file|
      require file
      name = File.basename(file, '.rb')
      context.extend const_get(name.camelize)
    end
  end

  def __super__(name, *args, **options, &block)
    method(name).super_method&.call(*args, **options, &block)
  end
end
