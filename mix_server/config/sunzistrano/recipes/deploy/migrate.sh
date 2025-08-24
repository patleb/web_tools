cd ${release_path}

desc 'Runs rake db:migrate'
rake db:migrate

cd.back
