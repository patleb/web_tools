require 'mix_task/configuration'

module MixBackup
  has_config do
    attr_writer :archive, :s3_versionned

    def s3_access_key_id
      Setting[:s3_access_key_id] || Setting[:aws_access_key_id]
    end

    def s3_secret_access_key
      Setting[:s3_secret_access_key] || Setting[:aws_secret_access_key]
    end

    def s3_region
      Setting[:s3_region] || Setting[:aws_region]
    end

    def s3_bucket
      if s3_versionned?
        "#{Setting[:s3_bucket]}-version"
      else
        Setting[:s3_bucket]
      end
    end

    def s3_versionned?
      @s3_versionned || ENV['S3_VERSIONNED'].to_b
    end

    def log_dir
      MixTask.config.shared_dir.join('log')
    end

    # TODO make it more flexible --> so a different mount point could be used
    def backup_dir
      MixTask.config.shared_dir.join('tmp', 'backups')
    end

    def backup_meta_file(model)
      backup_meta_dir.join(model, "#{remote? ? 'S3' : 'Local'}.yml")
    end

    def backup_meta_dir
      backup_dir.join('.data')
    end

    def backup_s3_path
      File.join('backups', backup_identifier)
    end

    def backup_local_path
      backup_dir.join(backup_identifier)
    end

    def backup_identifier
      "#{rails_app}_#{rails_env}"
    end

    def backup_model
      ENV['MODEL']
    end

    def backup_partition
      ENV['PARTITION']
    end

    def storage
      if remote?
        ::Backup::Storage::S3
      else
        ::Backup::Storage::Local
      end
    end

    def syncer
      if remote?
        ::Backup::Syncer::Cloud::S3
      else
        ::Backup::Syncer::RSync::Local
      end
    end

    def archive
      @archive || :data
    end

    # TODO add rsync storage
    def remote?
      Setting[:backup_storage] == 's3'
    end
  end
end
