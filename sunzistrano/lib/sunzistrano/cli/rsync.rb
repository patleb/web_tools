module Sunzistrano
  RSYNC_OPTIONS = '--archive --compress --partial --inplace --progress --verbose --human-readable' # equivalent to '-azPvh'

  Cli.class_eval do
    desc 'exist [STAGE] [PATH] [--deploy] [--from-defaults]', 'Check if path exists'
    method_options deploy: false, from_defaults: false
    def exist(stage, path)
      do_exist(stage, path)
    end

    desc 'download [STAGE] [PATH] [--dir] [--ref] [--deploy] [--from-defaults]', 'Download file(s)'
    method_options dir: :string, ref: false, deploy: false, from_defaults: false
    def download(stage, path)
      do_download(stage, path)
    end

    desc 'upload [STAGE] [PATH] [DIR] [--deploy] [--chown] [--chmod]', 'Upload file(s)'
    method_options deploy: false, chown: :string, chmod: :string
    def upload(stage, path, dir)
      do_upload(stage, path, dir)
    end

    no_tasks do
      def do_exist(stage, path)
        with_context(stage) do
          path = Sunzistrano.owner_path :defaults_dir, path.tr('/', '~') if sun.from_defaults
          run_exist_cmd(path)
        end
      end

      def do_download(stage, path)
        with_context(stage) do
          src = path
          if sun.ref
            dst = Setting.root.join(CONFIG_PATH, "files/#{src.delete_prefix('/')}.ref")
            dst.parent.mkpath
          else
            dst = sun.dir.present? ? Pathname.new(sun.dir).expand_path : Setting.root.join(BASH_DIR, 'downloads')
            dst.mkpath
          end
          src = Sunzistrano.owner_path :defaults_dir, src.tr('/', '~') if sun.from_defaults
          unless run_download_cmd(src, dst)
            raise "Cannot transfer [#{src}] to [#{dst}]"
          end
        end
      end

      def do_upload(stage, path, dir)
        with_context(stage) do
          src, dst = path, dir
          unless run_upload_cmd(src, dst)
            raise "Cannot transfer [#{src}] to [#{dst}]"
          end
        end
      end

      def run_exist_cmd(path)
        test = sun.sudo ? "sudo test -e #{path}" : "[[ -e #{path} ]]"
        system <<-SH.squish
          #{ssh_add_vagrant}
          #{ssh} #{sun.ssh_user}@#{sun.server_host} '#{test} && echo "true" || echo "false"'
        SH
      end

      def run_download_cmd(src, dst)
        system <<-SH.squish
          #{ssh_add_vagrant}
          rsync --rsync-path='sudo rsync' #{RSYNC_OPTIONS} -e
          '#{ssh}' '#{sun.ssh_user}@#{sun.server_host}:#{src}' '#{dst}'
        SH
      end

      def run_upload_cmd(src, dst)
        chown = sun.chown.presence || "#{sun.ssh_user}:#{sun.ssh_user}"
        chmod = "--chmod='#{sun.chmod}'" if sun.chmod.present?
        system <<-SH.squish
          #{ssh_add_vagrant}
          rsync --rsync-path='sudo rsync' #{RSYNC_OPTIONS} --chown='#{chown}' #{chmod} -e
          '#{ssh}' '#{src}' '#{sun.ssh_user}@#{sun.server_host}:#{dst}'
        SH
      end
    end
  end
end
