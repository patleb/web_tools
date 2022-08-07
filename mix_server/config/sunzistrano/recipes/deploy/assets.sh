keep_assets=${keep_assets:-10}

cd ${release_path}

desc 'Compile assets'
bin/rake assets:precompile

desc 'Cleanup expired assets'
bin/rake assets:clean[${keep_assets}]

cd.back
