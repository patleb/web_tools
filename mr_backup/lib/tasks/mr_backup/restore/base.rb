module MrBackup
  module Restore
    class Base < Base
      include ExtRake::Pg::Rescuable

      class NoTarFile < ::StandardError; end
      class NoWindowsSupport < ::StandardError; end
      class RootPath < ::StandardError; end

      def self.steps
        [:run_restore]
      end

      def self.args
        { db: ['--db=DB', 'DB type (ex.: --db=record would use Record::Base connection'] }
      end

      def self.backup_type
        raise NotImplementedError
      end

      def before_run
        super
        MrBackup.config.s3_versionned = options.s3_versionned
        ExtRake.config.db = options.db
        @restored = false
      end

      def sudo
        'sudo' if options.sudo
      end

      def mirror
        '--delete' if options.mirror
      end

      protected

      def run_restore
        return if @restored

        if MrBackup.config.remote?
          restore_s3
        else
          restore_local
        end
      end

      def restore_s3
        fetch_s3
        restore_local
      end

      def restore_local
        extract_tar unless options.sync_path

        cmd = restore_cmd
        _stdout, stderr, _status = Open3.capture3(cmd)

        if notify?(stderr)
          notify!(cmd, stderr)
        end

        if Gem.win_platform?
          FileUtils.remove_dir(local_storage, true)
        else
          sh "#{sudo} rm -rf #{extract_path}"
        end
      end

      def restore_cmd
        raise NotImplementedError
      end

      def fetch_s3
        return if Dir[local_storage.join('*.tar*')].any?

        bucket.objects.each do |s3_file|
          s3_key = s3_file.key

          if (file_name = file_match(s3_key))
            full_path = local_storage.join(file_name)
            FileUtils.mkdir_p(File.dirname(full_path))
            s3.client.get_object(bucket: bucket.name, key: s3_key, response_target: full_path)
          end
        end
      end

      def file_match(key)
        key.match(/^#{s3_storage}\/(.+)/).to_a.last
      end

      def extract_tar
        Dir.chdir(local_storage) do
          tar = "#{options.model}.tar"
          unless File.exist? tar
            if (tars = Dir["#{tar}*"]).empty?
              raise NoTarFile
            end
            if Gem.win_platform?
              sh "copy /b #{tars.sort.join(' + ')} #{tar}"
            else
              sh "cat #{tars.sort.join(' ')} > #{tar}"
            end
          end

          File.open(tar) do |tar_file|
            tar_package = Gem::Package::TarReader.new(tar_file)
            tar_package.rewind
            tar_package.each do |entry|
              if entry.file?
                FileUtils.mkdir_p(File.dirname(entry.full_name))
                File.open(entry.full_name, "wb") do |f|
                  f.write(entry.read)
                end
                File.chmod(entry.header.mode, entry.full_name)
                begin
                  File.chown(entry.header.uid, entry.header.gid, entry.full_name)
                rescue Errno::EPERM
                  # ignore
                end

                if Gem.win_platform?
                  sh %{7z e "#{entry.full_name}" "-o#{extract_path}"}
                end
              end
            end
            tar_package.close
          end
        end
      end

      def extract_path
        local_storage.join(options.model, self.class.backup_type)
      end

      def s3_storage
        @_s3_storage ||= File.join(MrBackup.config.backup_s3_path, directory.tr('-', '.'))
      end

      def local_storage
        @_local_storage ||= begin
          local_storage = MrBackup.config.backup_local_path.join(directory)
          FileUtils.mkdir_p local_storage
          local_storage
        end
      end

      def directory
        options.sync_path ? File.basename(options.sync_path) : File.join(options.model, options.version)
      end

      def bucket
        @_bucket ||= s3.bucket(MrBackup.config.s3_bucket)
      end

      def s3
        @_s3 ||= Aws::S3::Resource.new(
          access_key_id: MrBackup.config.s3_access_key_id,
          secret_access_key: MrBackup.config.s3_secret_access_key,
          region: MrBackup.config.s3_region
        )
      end
    end
  end
end
