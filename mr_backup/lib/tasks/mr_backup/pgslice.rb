module MrBackup
  module Pgslice
    extend ActiveSupport::Concern

    protected

    def pgslice_cmd
      @pgslice_cmd ||= begin
        cmd = "PGSLICE_URL=#{ExtRake.config.db_url} bundle exec pgslice"
        if self.class.respond_to? :gemfile
          cmd = "BUNDLE_GEMFILE=#{self.class.gemfile} #{cmd}"
        end
        cmd
      end
    end
  end
end
