module PgHero::Database::WithPublicSchema
  private

  def select_all(...)
    super.select do |row|
      next true unless (schema = row[:schema]).present?
      schema == 'public'
    end
  end
end

PgHero::Database.prepend PgHero::Database::WithPublicSchema
