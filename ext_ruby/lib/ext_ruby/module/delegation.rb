class Module
  def delegate_to(to, *methods, **options)
    options = options.merge(to: to)

    as_protected = options.delete(:protected)
    as_private = options.delete(:private)

    if options.delete(:writer)
      writers = methods.map{ |method| :"#{method}=" }

      delegate(*writers, **options)
    end

    delegate(*methods, **options)

    if (prefix = options[:prefix])
      prefix = options[:to] if prefix == true
      methods = methods.map{ |name| "#{prefix}_#{name}" }
    end

    protected *methods if as_protected
    private *methods if as_private
  end
end
