bundle_jobs=${bundle_jobs:-$(getconf _NPROCESSORS_ONLN)}
bundle_make_jobs=${bundle_make_jobs:-$(($(nproc) - 1 | 1))}
bundle_without=${bundle_without:-development:test}
if [[ -z "$bundle_without" || "$bundle_without" == false ]]; then
  bundle_deployment=${bundle_deployment:-true}
else
  bundle_deployment=${bundle_deployment:-false}
fi

cd ${release_path}

desc 'Bundle config'
if [[ $bundle_deployment == true ]]; then
  bin/bundle config --local deployment true
else
  bin/bundle config --local without $bundle_without
fi
bin/bundle config --local path "$shared_path/bundle"

desc 'Bundle install'
if bin/bundle check > /dev/null 2>&1; then
  echo "The Gemfile's dependencies are satisfied, skipping installation"
else
  MAKE="make -j ${bundle_make_jobs}" bin/bundle install --quiet --jobs ${bundle_jobs}
fi

cd.back
