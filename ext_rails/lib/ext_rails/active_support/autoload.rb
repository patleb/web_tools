module ActiveSupport::Autoload
  alias_method :autoload_without_call, :autoload
  def autoload(const_name, *, prepend: nil, include: nil, extend: nil)
    autoload_without_call(const_name, *)
    return unless prepend || include || extend
    constant = const_get(const_name)
    self.prepend constant if prepend
    self.include constant if include
    self.extend constant if extend
  end
end
