module MrBackup
  module Restore
    class Sync < Base
      def self.steps
        super + [:restore_permissions, :restore_owner]
      end

      def self.args
        {
          sync_path:     ['--sync-path=PATH',       'Destination path to synchronize'],
          s3_versionned: ['--[no-]s3-versionned',   'Specify if the s3 bucket is versionned'],
          sudo:          ['--[no-]sudo',            'Run as sudo'],
          mirror:        ['--[no-]mirror',          'Remove files not existing in the backup'],
          permissions:   ['--permissions=FILE_DIR', 'Restore permissions after sync (ex.: 0755 or 0644:0755)'],
          owner:         ['--owner=OWNER_GROUP',    'Restore ownership after sync (ex.: nobody or nobody:nogroup)'],
        }
      end

      def self.rsync_options
        ENV['RSYNC_OPTIONS'].presence || \
          "--recursive " \
          "--checksum " \
          "--quiet " \
          "--no-relative "
      end

      protected

      def restore_cmd
        raise NoWindowsSupport if Gem.win_platform?
        raise RootPath if options.sync_path.to_s.match /^\/*$/

        rsync_cmd = "rsync #{mirror} #{self.class.rsync_options} #{local_storage}/ '#{options.sync_path}'"

        "#{sudo} #{rsync_cmd}"
      end

      def restore_permissions
        return unless options.permissions.present?

        if (permissions = options.permissions.split(':')).size == 2
          permissions.reverse.zip(['d', 'f']).each do |(permission, type)|
            sh "#{sudo} find '#{options.sync_path}' -type #{type} -exec chmod #{permission} {} +"
          end
        else
          sh "#{sudo} chmod -R #{permissions.first} '#{options.sync_path}'"
        end
      end

      def restore_owner
        return unless options.owner.present?

        sh "#{sudo} chown -R #{options.owner} '#{options.sync_path}'"
      end
    end
  end
end
