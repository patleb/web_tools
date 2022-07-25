keep_assets=${keep_assets:-10}

cd ${release_path}

desc 'Compile assets'
RAILS_ENV=${env} RAILS_APP=${app} bin/rake assets:precompile

desc 'Cleanup expired assets'
RAILS_ENV=${env} RAILS_APP=${app} bin/rake assets:clean[${keep_assets}]

cd - > /dev/null
