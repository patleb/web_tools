class String
  def to_admin_param(separator = RailsAdmin::NAMESPACE_SEPARATOR)
    split('::').map(&:underscore).join(separator)
  end

  def to_admin_name(separator = RailsAdmin::NAMESPACE_SEPARATOR)
    split(separator).map(&:camelize).join('::')
  end
end
