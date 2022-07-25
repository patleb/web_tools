RBENV_PATH=$HOME/.rbenv
RBENV_RUBY_DIR="$RBENV_PATH/versions/${ruby_version}"

desc 'Validate rbenv'
if [[ ! -d $RBENV_RUBY_DIR ]]; then
  echo.red "rbenv: ${ruby_version} is not installed or not found in $RBENV_RUBY_DIR on ${server_host}"
  exit 1
fi
