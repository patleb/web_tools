module MrBackup
  module Backup
    class Git < ActiveTask::Base
      def self.steps
        [:run_backup]
      end

      def self.git_directory
        Pathname.new(Secret[:backup_git_directory]).expand_path
      end

      protected

      def run_backup
        Dir.chdir(self.class.git_directory) do
          unless nothing_to_commit?
            add_all
            commit_all
          end
          push
        end
      end

      def remove_tilde_files
        FileUtils.rm_rf Dir.glob(self.class.git_directory.join('**', '~*').to_s)
      end

      def nothing_to_commit?
        status.include? 'nothing to commit, working'
      end

      def add_all
        sh 'git add -A'
      end

      def commit_all
        sh %{git commit -m "backup #{Time.current.utc}"}
      end

      def push
        sh 'eval $(ssh-agent) && ssh-add 2> /dev/null && git push'
      end

      def status
        @_status ||= begin
          status = `git status`
          puts status
          status
        end
      end
    end
  end
end
