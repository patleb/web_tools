source 'sunzistrano/config/provision/helpers/sun_helper.sh'
source 'sunzistrano/config/provision/helpers/sun/recipe_helper.sh'
source 'sunzistrano/config/provision/helpers/sun/template_helper.sh'
source 'sunzistrano/config/provision/helpers/sun/version_helper.sh'

assert_file_not_contains() {
  local -r file="$1"
  local -r regex="$2"
  if grep -q "$regex" "$file"; then
    local -r rem="${BATSLIB_FILE_PATH_REM-}"
    local -r add="${BATSLIB_FILE_PATH_ADD-}"
    batslib_print_kv_single 4 'path' "${file/$rem/$add}" \
      | batslib_decorate 'file does contain regex' \
      | fail
  fi
}

sun.test_setup() {
  load "$(pwd)/vendor/bats-core/bats-support/load"
  load "$(pwd)/vendor/bats-core/bats-assert/load"
  load "$(pwd)/vendor/bats-core/bats-file/load"
  ROOT=$(pwd)
  TEST="$(cd "$(dirname $(dirname "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
  HOME_STUB="$TEST/fixtures/files/home"
  HOME_WAS=$HOME
  HOME=$HOME_STUB
  __PROVISION_LOG__=sun_provision.log
  __PROVISION_DIR__=sun_provision
  __MANIFEST_LOG__=sun_manifest.log
  __MANIFEST_DIR__=sun_manifest
  __METADATA_DIR__=sun_metadata
  __DEFAULTS_DIR__=sun_defaults
  __ROLLBACK__=${__ROLLBACK__:-false}
  __SPECIALIZE__=${__SPECIALIZE__:-false}
  __DEBUG__=${__DEBUG__:-false}
  sun.initialize
}

sun.test_teardown() {
  if [[ "$HOME" == "$HOME_STUB" ]]; then
    rm -rf "$HOME/$__DEFAULTS_DIR__"
    rm -rf "$HOME/$__MANIFEST_DIR__"
    rm -rf "$HOME/$__METADATA_DIR__"
    rm -f "$HOME/$__MANIFEST_LOG__"
  fi
  HOME=$HOME_WAS
}
