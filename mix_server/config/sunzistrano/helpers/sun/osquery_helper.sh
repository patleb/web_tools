sun.osquery_restart() {
  if sun.osquery_check; then
    if sudo osqueryctl restart; then
      echo 'Osquery restarted'
    else
      echo.red 'Could not restart Osquery.'
      exit 1
    fi
  fi
}

sun.osquery_check() {
  if [[ $(sudo osqueryctl config-check 2>&1 >/dev/null | grep -c 'Error reading') -eq 0 ]]; then
    echo 'Config [OK]'
    return 0
  else
    echo.red 'Osquery configuration is invalid! (Make sure osquery configuration files are readable and correctly formated.)'
    exit 1
  fi
}
