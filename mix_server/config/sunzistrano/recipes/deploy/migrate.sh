cd ${release_path}

desc 'Runs rake db:migrate'
RAILS_ENV=${env} RAILS_APP=${app} bin/rake db:migrate

cd - > /dev/null
