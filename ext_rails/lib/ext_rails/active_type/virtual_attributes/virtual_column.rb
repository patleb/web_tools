ActiveType::VirtualAttributes::VirtualColumn.class_eval do
  alias_method :cast, :type_cast

  def type
    @type_caster.ivar(:@type)
  end
end
