module ActiveTask
  module Helpers
    extend ActiveSupport::Concern

    prepended do
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::NumberHelper
    end

    class_methods do
      def cap_working_dir; end
    end

    protected

    def settings_reload
      Setting.reload
    end

    private

    def cap(command)
      command = "eval $(ssh-agent) && ssh-add 2> /dev/null && RAILS_ENV=development bundle exec cap #{command}"
      if (working_dir = self.class.cap_working_dir).present?
        Dir.chdir(working_dir) do
          sh_clean command
        end
      else
        sh_clean command
      end
    end

    # NOTE needed only if using a different Gemfile
    def sh_clean(*cmd, &block)
      Bundler.with_clean_env do
        rake.__send__ :sh, *cmd, &block
      end
    end

    def puts_downloading(file_name, remainder, total)
      remainder = number_to_human_size remainder
      total = number_to_human_size total
      puts "Downloading #{file_name}[#{Process.pid}][#{total}] remaining #{remainder}"
    end

    def puts_step(name)
      puts "[#{Time.current.utc}]#{ExtRake::STEP}[#{Process.pid}] #{name}".yellow
    end

    def puts_cancel
      puts "[#{Time.current.utc}]#{ExtRake::CANCEL}[#{Process.pid}]".red
    end

    def puts_info(tag, text = nil)
      puts "[#{Time.current.utc}]#{tag}[#{Process.pid}] #{text}"
    end
  end
end
