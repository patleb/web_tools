namespace :osquery do
  desc 'configure osquery'
  task :configure => :environment do
    conf = compile 'config/deploy/templates/osquery/osquery.conf'
    flags = compile 'config/deploy/templates/osquery/osquery.flags'
    sh "sudo mv #{conf} /etc/osquery/osquery.conf"
    sh "sudo mv #{flags} /etc/osquery/osquery.flags"
  end
end
