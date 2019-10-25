class Numeric
  def to_sql
    infinite? ? "'#{self}'::DOUBLE PRECISION".sql_safe : self
  end
end
