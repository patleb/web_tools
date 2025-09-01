module Sunzistrano
  RSYNC_ARCHIVE = '--archive --compress'
  RSYNC_RESUME = '--partial --inplace'
  RSYNC_VERBOSE = '--progress --verbose --human-readable'

  Cli.class_eval do
    desc 'exist [STAGE] [PATH] [--deploy] [--from-defaults]', 'Check if path exists'
    method_options deploy: false, from_defaults: false
    def exist(stage, path) = do_exist(stage, path)

    desc 'download [STAGE] [PATH] [--dir] [--ref] [--deploy] [--from-defaults] [-no-resume] [-no-verbose] [-no-decompress]', 'Download file(s)'
    method_options dir: :string, ref: false, deploy: false, from_defaults: false, resume: true, decompress: true, verbose: true
    def download(stage, path) = do_download(stage, path)

    desc 'upload [STAGE] [PATH] [DIR] [--deploy] [--chown] [--chmod] [-no-resume] [-no-verbose]', 'Upload file(s)'
    method_options deploy: false, chown: :string, chmod: :string, resume: true, verbose: true
    def upload(stage, path, dir) = do_upload(stage, path, dir)

    no_tasks do
      def do_exist(stage, path)
        with_context(stage) do
          path = owner_path :defaults_dir, path.tr('/', '~') if sun.from_defaults
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
          src = owner_path :defaults_dir, src.tr('/', '~') if sun.from_defaults
          unless run_download_cmd(src, dst)
            raise "Cannot transfer [#{src}] to [#{dst}]"
          end
          system "unpigz #{dst}" if sun.decompress && dst.extname == '.gz'
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
          #{ssh_virtual_key}
          #{ssh_cmd} #{sun.ssh_user}@#{sun.server_host} '#{test} && echo "true" || echo "false"'
        SH
      end

      def run_download_cmd(src, dst)
        system <<-SH.squish
          #{ssh_virtual_key}
          rsync --rsync-path='sudo rsync' #{rsync_options} -e
          '#{ssh_cmd}' '#{sun.ssh_user}@#{sun.server_host}:#{src}' '#{dst}'
        SH
      end

      def run_upload_cmd(src, dst)
        chown = sun.chown.presence || "#{sun.ssh_user}:#{sun.ssh_user}"
        chmod = "--chmod='#{sun.chmod}'" if sun.chmod.present?
        system <<-SH.squish
          #{ssh_virtual_key}
          rsync --rsync-path='sudo rsync' #{rsync_options} --chown='#{chown}' #{chmod} -e
          '#{ssh_cmd}' '#{src}' '#{sun.ssh_user}@#{sun.server_host}:#{dst}'
        SH
      end

      def rsync_options
        "#{RSYNC_ARCHIVE} #{RSYNC_RESUME if options.resume} #{RSYNC_VERBOSE if options.verbose}"
      end
    end
  end
end
