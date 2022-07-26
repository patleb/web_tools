if [[ "${system}" == true ]]; then
  desc 'Add config/secrets.yml'
  sun.copy "$shared_path/$(sun.flatten_path config/secrets.yml)"
fi
