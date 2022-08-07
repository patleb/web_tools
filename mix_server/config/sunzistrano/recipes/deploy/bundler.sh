bundle_jobs=${bundle_jobs:-4}

cd ${release_path}

desc 'Bundle config'
bin/bundle config --local deployment true
bin/bundle config --local path "$shared_path/bundle"
bin/bundle config --local without development:test

desc 'Bundle install'
if bin/bundle check > /dev/null 2>&1; then
  echo "The Gemfile's dependencies are satisfied, skipping installation"
else
  bin/bundle install --quiet --jobs ${bundle_jobs}
fi

cd.back
