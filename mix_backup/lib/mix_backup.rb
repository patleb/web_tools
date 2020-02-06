module MixBackup
  autoload :Pgslice,      'tasks/mix_backup/pgslice'
  autoload :Base,         'tasks/mix_backup/base'

  module Backup
    autoload :Base,       'tasks/mix_backup/backup/base'
    autoload :Partition,  'tasks/mix_backup/backup/partition'
  end

  module Partition
    autoload :Base,       'tasks/mix_backup/partition/base'
  end

  module Restore
    autoload :Archive,    'tasks/mix_backup/restore/archive'
    autoload :Base,       'tasks/mix_backup/restore/base'
    autoload :PostgreSQL, 'tasks/mix_backup/restore/postgresql'
    autoload :Sync,       'tasks/mix_backup/restore/sync'
  end
end
