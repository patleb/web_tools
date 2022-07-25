source 'sunzistrano/config/sunzistrano/helpers/sun_helper.sh'
source 'sunzistrano/config/sunzistrano/helpers/sun/color_helper.sh'
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
  role=${1:-system}
  env=test
  app=local_app
  repo_url="$TEST/fixtures/files/local_app.git"
  branch=develop
  revision=c686b37dcf12835aa406450b6aa9c64a2ac0fbc9
  bash_dir=$HOME/.sunzistrano
  bash_log=$HOME/sun_bash.log
  defaults_dir=$HOME/sun_defaults
  manifest_dir=$HOME/sun_manifest
  manifest_log=$HOME/sun_manifest.log
  metadata_dir=$HOME/sun_metadata
  deploy=${deploy:-false}
  system=${system:-false}
  provision=${provision:-false}
  specialize=${specialize:-false}
  rollback=${rollback:-false}
  debug=${debug:-false}
  sun.initialize
  source 'sunzistrano/config/sunzistrano/roles/web/load_defaults.sh'
  source 'sunzistrano/config/sunzistrano/roles/web/git_wrapper.sh'
}

sun.test_teardown() {
  cd $ROOT
  if [[ -f $GIT_SSH ]]; then
    rm -f $GIT_SSH
  fi
  if [[ "$HOME" == "$HOME_STUB" ]]; then
    rm -rf "${defaults_dir}"
    rm -rf "${manifest_dir}"
    rm -rf "${metadata_dir}"
    rm -f "${manifest_log}"
  fi
  if [[ $deploy_path == "$HOME/web-test-local_app" ]]; then
    rm -rf $deploy_path
    rm "$HOME/.gitconfig"
  fi
  HOME=$HOME_WAS
}