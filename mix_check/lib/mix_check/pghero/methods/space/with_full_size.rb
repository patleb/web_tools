module PgHero::Methods::Space::WithFullSize
  extend ActiveSupport::Concern

  included do
    alias_method :relation_table_only_sizes, :relation_sizes
    define_method :relation_sizes do
      table_sizes.map!{ |row| row.tap{ |item| item[:relation] = item.delete(:table) } }
    end
  end
end

PgHero::Methods::Space.include PgHero::Methods::Space::WithFullSize
