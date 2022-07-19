source 'sunzistrano/test/bash/spec_helper.sh'

setup() {
  sun.test_setup
  TMP_TEMPLATE=/tmp/template
}

teardown() {
  rm -f $TMP_TEMPLATE
  sun.test_teardown
}

@test 'sun.backup_defaults and sun.remove_defaults' {
  echo 'default template' > $TMP_TEMPLATE
  run sun.backup_defaults $TMP_TEMPLATE
  assert_file_contains "${defaults_dir}/$(sun.flatten_path $TMP_TEMPLATE)" 'default template'
  run sun.remove_defaults $TMP_TEMPLATE
  assert_not_exists "${defaults_dir}/$(sun.flatten_path $TMP_TEMPLATE)"
}

@test 'sun.move' {
  local template=$(sun.template_path $TMP_TEMPLATE)
  assert_equal $template "${bash_dir}/files$TMP_TEMPLATE"
  cp $template "$template.bkp"
  run sun.move $TMP_TEMPLATE
  assert_file_contains $TMP_TEMPLATE 'overriden template'
  mv "$template.bkp" $template
}

@test 'sun.compile' {
  export TEMPLATE_CONTENT='overriden template'
  run sun.compile $TMP_TEMPLATE
  assert_file_contains $TMP_TEMPLATE 'overriden template'
  assert_output "Compiled \"$TMP_TEMPLATE\""
}

@test 'sun.compare_defaults' {
  echo 'default template' > $TMP_TEMPLATE
  sun.backup_defaults $TMP_TEMPLATE
  run sun.compare_defaults $TMP_TEMPLATE
  assert_output ''
}

@test 'sun.compare_defaults diff' {
  echo 'different template' > $TMP_TEMPLATE
  sun.backup_defaults $TMP_TEMPLATE
  run sun.compare_defaults $TMP_TEMPLATE
  assert_failure
}
