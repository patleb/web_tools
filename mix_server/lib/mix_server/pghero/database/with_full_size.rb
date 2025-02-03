module PgHero::Database::WithFullSize
  def database_size(pretty = false)
    return super() if pretty
    select_one("SELECT pg_database_size(current_database())")
  end

  def relation_sizes(type = :full)
    case type.to_sym
    when :full    then table_sizes.map!{ |row| row.tap{ |item| item[:relation] = item.delete(:table) } }
    when :table   then super().select{ |row| row[:type] == 'table' }
    when :matview then super().select{ |row| row[:type] == 'matview' }
    when :index   then super().select{ |row| row[:type] == 'index' }
    else super()
    end
  end
end

PgHero::Database.prepend PgHero::Database::WithFullSize
