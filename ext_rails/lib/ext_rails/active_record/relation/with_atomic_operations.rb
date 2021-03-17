module ActiveRecord::Relation::WithAtomicOperations
  def first_or_create!(...)
    super
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def find_or_create_by!(...)
    super
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
