class String
  include Numeric::Conversions

  def to_admin_param
    split('::').map(&:underscore).join('-')
  end

  def to_admin_name
    split('-').map(&:camelize).join('::')
  end
end
