module MixBackup
  module Restore
    class Archive < Base
      def self.args
        {
          model:   ['--model=MODEL',     'Backup model'],
          version: ['--version=VERSION', 'Backup version'],
          sudo:    ['--[no-]sudo',       'Run as sudo'],
          mirror:  ['--[no-]mirror',     'Remove files not existing in the backup'],
        }
      end

      def self.backup_type
        'archives'
      end

      def self.rsync_options
        ENV['RSYNC_OPTIONS'].presence || \
          "--archive " \
          "--quiet " \
          "--no-relative "
      end

      def self.tar_options
        ENV['TAR_OPTIONS'].presence || \
          "--same-owner " \
          "--same-permissions "
      end

      protected

      def restore_cmd
        raise NoWindowsSupport if Gem.win_platform?

        backup_name = "#{MixBackup.config.archive}.tar.gz"
        backup = extract_path.join(backup_name)

        tar_cmd = "tar #{self.class.tar_options} -xzf '#{backup}' --directory='#{extract_path}'"
        rsync_cmd = "rsync #{mirror} #{self.class.rsync_options} --exclude=#{backup_name} #{extract_path}/ '/'"

        "#{sudo} #{tar_cmd} && #{sudo} #{rsync_cmd}"
      end
    end
  end
end
