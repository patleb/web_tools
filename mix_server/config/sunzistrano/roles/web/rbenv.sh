rbenv_ruby_dir="$HOME/.rbenv/versions/${ruby_version}"
if [[ ! -d $rbenv_ruby_dir ]]; then
  echo.red "rbenv: ${ruby_version} is not installed or not found in $rbenv_ruby_dir on ${server_host}"
  exit 1
fi

<%= Sh.rbenv_export %>
<%= Sh.rbenv_init %>
