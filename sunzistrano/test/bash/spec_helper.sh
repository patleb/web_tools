test.load_bats_plugins() {
  load "$(pwd)/vendor/bats-core/bats-support/load"
  load "$(pwd)/vendor/bats-core/bats-assert/load"
  load "$(pwd)/vendor/bats-core/bats-file/load"
}

test.stub_home() {
  HOME_STUB="$(pwd)/tmp/bats/home"
  HOME_WAS=$HOME
  HOME=$HOME_STUB
  mkdir -p $HOME
}

test.unstub_home() {
  rm -rf $HOME_STUB
  HOME=$HOME_WAS
}
