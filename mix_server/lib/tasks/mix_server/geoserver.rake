namespace :geoserver do
  namespace :workspace do
    %w(Create Destroy).each do |action|
      task_name = action.underscore

      desc "#{task_name.humanize} GeoServer workspace"
      task task_name => :environment do |t|
        Geoserver::Workspace.const_get(action).new(self, t).run!
      end
    end
  end
end
