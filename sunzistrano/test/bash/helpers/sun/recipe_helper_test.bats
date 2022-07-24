source 'sunzistrano/test/bash/spec_helper.sh'

setup() {
  sun.test_setup
  cd "${bash_dir}"
}

teardown() {
  sun.test_teardown
}

@test 'sun.source_recipe and rollback' {
  run sun.source_recipe 'recipe-{version}' 'recipe-1'
  assert_output --partial 'RECIPE_ID=recipe-1'
  assert_file_contains "${manifest_log}" "Done \[recipe-1]"
  rollback=true
  run sun.source_recipe 'recipe-{version}' 'recipe-1'
  assert_output --partial 'RECIPE_ID_ROLLBACK=recipe-1'
  refute_output --partial 'RECIPE_ID=recipe-1'
  assert_file_not_contains "${manifest_log}" "Done \[recipe-1]"
}

@test 'sun.source_recipe specialize' {
  specialize=true
  run sun.source_recipe 'recipe-{version}' 'recipe-1'
  assert_output --partial 'RECIPE_ID_SPECIALIZE=recipe-1-specialize'
  refute_output --partial 'RECIPE_ID=recipe-1'
  assert_file_contains "${manifest_log}" "Done \[recipe-1-specialize]"
}
