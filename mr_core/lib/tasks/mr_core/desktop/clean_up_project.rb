module MrCore
  module Desktop
    class CleanUpProject < ActiveTask::Base
      CHMOD_777 = 'rwxrwxrwx'
      CHMOD_755 = 'rwxr-xr-x'
      CHMOD_644 = 'rw-r--r--'
      PERMISSIONS = [CHMOD_777, CHMOD_755, CHMOD_644]

      attr_accessor :fullpath

      def self.steps
        %i(
          set_fullpath
          enable_git_permission_reset
          restore
        )
      end

      def self.args
        { path: ['--path=PATH', 'Directory of the application'] }
      end

      def self.authorized_paths
        Setting[:authorized_paths]
      end

      protected

      def set_fullpath
        self.fullpath = Pathname.new(options.path) and return if options.path.include? '/'

        # https://ruby-doc.org/stdlib-2.0.0/libdoc/find/rdoc/Find.html
        roots = (self.class.authorized_paths.presence || '').split(';')
        roots << Rails.root.to_s.sub(/\/\w+$/, '')
        roots.each do |root_name|
          dirs = Pathname.new(root_name).children.select(&:directory?)
          if (dir = dirs.find{ |d| d.basename.to_s == options.path })
            self.fullpath = dir
            break
          end
        end

        raise 'folder not found' unless fullpath
      end

      def enable_git_permission_reset
        return if `git config --get-regexp permission-reset`.present?

        git_permission_reset = <<~SH
          git diff -p -R --no-color \
            | grep -E "^(diff|(old|new) mode)" --color=never \
            | git apply
        SH

        sh "git config --global --add alias.permission-reset '!#{git_permission_reset.strip}'"
      end

      def restore
        Dir.chdir(fullpath) do
          rm_rf fullpath.join('.idea')

          ['', 'spec/dummy/', 'spec/dummy_app/'].each do |base|
            ['tmp', 'log'].each do |dir|
              sh "find ./#{base}#{dir} ! -name .keep -type f -exec rm -f {} +" rescue nil
              sh "find ./#{base}#{dir} ! -path ./#{base}#{dir} -type d -exec rm -rf {} +" rescue nil
            end
          end

          Dir.glob("#{fullpath}/**/").each do |dir|
            sh "chmod 755 #{dir}"
          end

          if Dir.exist? '.git'
            sh "git permission-reset" rescue nil
            sh "chmod 755 .git"
            permissions = `ls -laR #{fullpath.join('.git')}`.split("\n").select{ |line| line.match /^(-|d)/ }.map{ |line| line[1...10] }.uniq
            raise 'verify .git folder permissions' unless permissions.all?{ |p| p.in? PERMISSIONS }
            sh "find .git -type d -exec chmod 755 {} \\;"
            sh "find .git -type f -exec chmod 644 {} \\;"
          end
        end
      end
    end
  end
end
