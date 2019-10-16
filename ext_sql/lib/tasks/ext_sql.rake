require_rel 'ext_sql'

namespace :db do
  namespace :pg do
    %w(drop_all dump restore truncate).each do |name|
      desc "-- [options] #{name.humanize}"
      task name.to_sym => :environment do |t|
        "::Db::Pg::#{name.camelize}".constantize.new(self, t).run
      end
    end
  end
end
