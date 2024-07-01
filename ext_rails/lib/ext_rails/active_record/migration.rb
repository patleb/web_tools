require_dir __FILE__, 'migration'

ActiveRecord::Migration.class_eval do
  include self::WithPartition
  include self::WithReference
  include self::WithUnaccent
end
