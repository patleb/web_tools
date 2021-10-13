namespace :geoserver do
  desc 'Start geoserver'
  task :start => :environment do
    sh 'sudo systemctl start geoserver'
  end

  desc 'Stop geoserver'
  task :stop => :environment do
    sh 'sudo systemctl stop geoserver'
  end

  namespace :workspace do
    desc "Create GeoServer workspace"
    task :create => :environment do |t|
      Geoserver::Workspace::Create.new(self, t).run!
    end

    desc "Destroy GeoServer workspace"
    task :destroy, [:silent] => :environment do |t, args|
      if flag_on? args, :silent
        Geoserver::Workspace::Destroy.new(self, t).run
      else
        Geoserver::Workspace::Destroy.new(self, t).run!
      end
    end
  end
end
