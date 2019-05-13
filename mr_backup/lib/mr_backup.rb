module MrBackup
  autoload :Pgslice,      'tasks/mr_backup/pgslice'
  autoload :Base,         'tasks/mr_backup/base'

  module Backup
    autoload :Base,       'tasks/mr_backup/backup/base'
    autoload :Partition,  'tasks/mr_backup/backup/partition'
  end

  module Partition
    autoload :Base,       'tasks/mr_backup/partition/base'
  end

  module Restore
    autoload :Archive,    'tasks/mr_backup/restore/archive'
    autoload :Base,       'tasks/mr_backup/restore/base'
    autoload :PostgreSQL, 'tasks/mr_backup/restore/postgresql'
    autoload :Sync,       'tasks/mr_backup/restore/sync'
  end
end
