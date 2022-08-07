cd ${release_path}

desc 'Runs rake db:migrate'
bin/rake db:migrate

cd.back
