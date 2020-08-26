require_rel 'migration'

ActiveRecord::Migration.class_eval do
  include self::WithReference
end
