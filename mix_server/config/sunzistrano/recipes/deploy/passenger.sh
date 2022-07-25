cd ${release_path}

desc 'Restart your Passenger application'
rbenv sudo passenger-config restart-app ${deploy_path} --ignore-app-not-running

cd - > /dev/null
