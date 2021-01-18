module Backup
  class Package
    attr_accessor :time, :chunk_suffixes
  end
end

module MixBackup
  module Backup
    class Base < Base
      class InvalidModel < ::StandardError; end
      class Failed < ::StandardError; end

      def self.steps
        [:run_backup!]
      end

      def self.args
        {
          model:         ['--model=MODEL',        'Backup model'],
          sync:          ['--[no-]sync',          'Prevents running meta trigger'],
          s3_versionned: ['--[no-]s3-versionned', 'Same as sync option and specify if the s3 bucket is versionned'],
          sudo:          ['--[no-]sudo',          'Run as sudo'],
          db:            ['--db=DB',              'DB type (ex.: --db=record would use Record::Base connection'],
        }
      end

      def self.gemfile
        'Gemfile'
      end

      def self.backup_root
        MixTask.config.rails_root.join('config', 'backup')
      end

      def before_run
        super
        MixBackup.config.s3_versionned = options.s3_versionned
        MixTask.config.db = options.db
      end

      def sudo
        options.sudo ? 'rbenv sudo' : ''
      end

      def backup_env
        [
          "BUNDLE_GEMFILE=#{self.class.gemfile}",
          "RAILS_ENV=#{MixTask.config.rails_env}",
          "RAILS_APP=#{MixTask.config.rails_app}",
          "RAILS_ROOT=#{MixTask.config.rails_root}",
          "MODEL=#{options.model}",
          "S3_VERSIONNED=#{options.s3_versionned}",
          "DB=#{options.db}",
        ]
      end

      protected

      def run_backup!
        raise Failed unless run_backup
      end

      def run_backup
        config_models = %w(app_logs sys_logs meta)
        model = options.model.to_s
        system = config_models.include? model
        unless system || self.class.backup_root.join('models', "#{model}.rb").exist?
          raise InvalidModel
        end

        backup_cmd = "bundle exec backup perform"
        backup_opt = [
          "--trigger #{model}#{',meta' unless system || options.sync || options.s3_versionned}",
          "--config_file #{self.class.backup_root.join('config.rb')}"
        ]

        sh_clean [sudo, backup_env, backup_cmd, backup_opt].join(' ') do |ok, result|
          # on failure, an email should have been sent by the backup gem
          @failed = (!ok && result.exitstatus != 1)
        end

        !@failed
      end

      def meta_entry
        meta_data.first
      end

      def meta_data
        @_meta_data ||= YAML.load(MixBackup.config.backup_meta_file(options.model).read)
      end
    end
  end
end
