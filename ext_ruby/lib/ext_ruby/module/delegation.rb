class Module
  def delegate_to(to, *methods, **options)
    options = options.merge(to: to)
    delegate(*methods, **options)
  end
end
