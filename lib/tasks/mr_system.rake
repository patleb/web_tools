require_rel 'mr_system'

namespace :mr_system do
  desc 'setup environments and .gitignore files'
  task :setup do
    src, dst = Gem.root('mr_system').join('lib/tasks/templates'), Rails.root

    %w(development staging vagrant).each do |env|
      cp  src.join("config/environments/#{env}.rb"), dst.join("config/environments/#{env}.rb")
    end
    write dst.join('config/environments/production.rb'), ERB.template(src.join('config/environments/production.rb.erb'), binding)

    %w(/vendor/ruby /.vscode/* /.idea/* .editorconfig .generators .rakeTasks).each do |ignore|
      gitignore dst, ignore
    end
  end
end

namespace :desktop do
  desc "-- [options] Desktop Clean-up Project"
  task :clean_up_project => :environment do |t|
    MrSystem::Desktop::CleanUpProject.new(self, t).run
  end

  desc "-- [options] Desktop Update Application"
  task :update_application => :environment do |t|
    MrSystem::Desktop::UpdateApplication.new(self, t).run
  end
end

namespace :vpn do
  desc "-- [options] VPN Update IP"
  task :update_ip => :environment do |t|
    MrSystem::Vpn::UpdateIp.new(self, t).run
  end
end

namespace :vagrant do
  desc 'install ~/.vagrant.d/Vagrantfile'
  task :copy_file do
    vagrantfile = Gem.root('mr_system').join('lib/tasks/mr_system/Vagrantfile').to_s
    cp vagrantfile, File.expand_path('~/.vagrant.d/Vagrantfile')
  end
end

namespace :gem do
  desc 'destroy gem'
  task :destroy, [:name] do |t, args|
    name = args[:name]
    except = ENV['EXCEPT'].to_s.split(',')
    `gem list -r '^#{name}$' --remote --all`.match(/\((.+)\)/)[1].split(', ').each do |version|
      if version.in? except
        puts "skipped version [#{version}]"
      else
        puts `gem yank #{name} -v #{version}`
      end
    end
  end
end
