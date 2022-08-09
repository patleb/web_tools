profiler_matcher=${profiler_matcher:-''}

if [[ -z "${profiler_matcher}" ]]; then
  echo.failure 'cannot start profiler with empty matcher'
  exit 1
fi
echo "${profiler_matcher}" > "$current_path/tmp/profile.txt"
passenger.restart
