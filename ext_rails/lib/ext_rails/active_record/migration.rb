require_rel 'migration'

ActiveRecord::Migration.class_eval do
  include self::WithPartition
  include self::WithReference
  include self::WithUnaccent
end
