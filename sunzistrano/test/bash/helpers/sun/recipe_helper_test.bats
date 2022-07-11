source 'sunzistrano/test/bash/spec_helper.sh'

setup() {
  sun.test_setup
  cd "$HOME/$__PROVISION_DIR__"
}

teardown() {
  cd $ROOT
  sun.test_teardown
}

@test 'sun.source_recipe and rollback' {
  run sun.source_recipe 'recipe__VERSION__' 'recipe-1'
  assert_output --partial 'RECIPE_ID=recipe-1'
  assert_file_contains "$HOME/$__MANIFEST_LOG__" "Done \[recipe-1]"
  __ROLLBACK__=true
  run sun.source_recipe 'recipe__VERSION__' 'recipe-1'
  assert_output --partial 'RECIPE_ID_ROLLBACK=recipe-1'
  refute_output --partial 'RECIPE_ID=recipe-1'
  assert_file_not_contains "$HOME/$__MANIFEST_LOG__" "Done \[recipe-1]"
}

@test 'sun.source_recipe all' {
  run sun.source_recipe 'all'
  assert_output --partial 'RECIPE_ID=recipe-1'
  refute_output --partial 'RECIPE_ID=all'
  assert_file_contains "$HOME/$__MANIFEST_LOG__" "Done \[recipe-1]"
}

@test 'sun.source_recipe specialize' {
  __SPECIALIZE__=true
  run sun.source_recipe 'recipe__VERSION__' 'recipe-1'
  assert_output --partial 'RECIPE_ID_SPECIALIZE=recipe-1-specialize'
  refute_output --partial 'RECIPE_ID=recipe-1'
  assert_file_contains "$HOME/$__MANIFEST_LOG__" "Done \[recipe-1-specialize]"
}
