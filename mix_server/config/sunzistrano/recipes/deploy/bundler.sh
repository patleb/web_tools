bundle_jobs=${bundle_jobs:-4}

cd ${release_path}

desc 'Bundler config'
bin/bundle config --local deployment true
bin/bundle config --local bundle_path "${shared_path}/bundle"
bin/bundle config --local without development:test

desc 'Bundler install'
if bin/bundle check; then
  echo "The Gemfile's dependencies are satisfied, skipping installation"
else
  bin/bundle install --quiet --jobs ${bundle_jobs}
fi

cd - > /dev/null
