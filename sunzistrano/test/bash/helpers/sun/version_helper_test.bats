source 'sunzistrano/test/bash/spec_helper.sh'

setup() {
  sun.test_setup
}

teardown() {
  sun.test_teardown
}

@test 'sun.major_version' {
  run sun.major_version '10.1.2'
  assert_output '10'
  run sun.major_version '11.2'
  assert_output '11'
  run sun.major_version '12'
  assert_output '12'
}

@test 'sun.available_version' {
  run sun.available_version 'postgresql-client'
  assert_output --partial 'pgdg'
}

@test 'sun.installed_version' {
  run sun.installed_version 'postgresql-client'
  assert_output --partial 'pgdg'
}
