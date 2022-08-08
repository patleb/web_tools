osquery.start() {
  if osquery.check; then
    if sudo osqueryctl start; then
      echo 'Osquery started'
    else
      echo.red 'Could not start Osquery.'
      exit 1
    fi
  fi
}

osquery.stop() {
  if sudo osqueryctl stop; then
    echo 'Osquery stopped'
  else
    echo.red 'Could not stop Osquery.'
    exit 1
  fi
}

osquery.restart() {
  if osquery.check; then
    if sudo osqueryctl restart; then
      echo 'Osquery restarted'
    else
      echo.red 'Could not restart Osquery.'
      exit 1
    fi
  fi
}

osquery.check() {
  if [[ $(sudo osqueryctl config-check 2>&1 >/dev/null | grep -c 'Error reading') -eq 0 ]]; then
    echo 'Config [OK]'
    return 0
  else
    echo.red 'Osquery configuration is invalid! (Make sure osquery configuration files are readable and correctly formated.)'
    exit 1
  fi
}
