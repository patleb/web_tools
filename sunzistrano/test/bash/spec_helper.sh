source 'sunzistrano/config/sunzistrano/helpers/sun_helper.sh'
source 'sunzistrano/config/sunzistrano/helpers/sun/recipe_helper.sh'
source 'sunzistrano/config/sunzistrano/helpers/sun/template_helper.sh'
source 'sunzistrano/config/sunzistrano/helpers/sun/version_helper.sh'

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
  bash_log=sunzistrano.log
  bash_dir=sunzistrano
  manifest_log=sun_manifest.log
  manifest_dir=sun_manifest
  metadata_dir=sun_metadata
  defaults_dir=sun_defaults
  rollback=${rollback:-false}
  specialize=${specialize:-false}
  debug=${debug:-false}
  sun.initialize
}

sun.test_teardown() {
  if [[ "$HOME" == "$HOME_STUB" ]]; then
    rm -rf "$HOME/${defaults_dir}"
    rm -rf "$HOME/${manifest_dir}"
    rm -rf "$HOME/${metadata_dir}"
    rm -f "$HOME/${manifest_log}"
  fi
  HOME=$HOME_WAS
}
