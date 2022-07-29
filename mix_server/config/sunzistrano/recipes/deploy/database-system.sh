if ! sun.psql "SELECT 1 FROM pg_roles WHERE rolname='${db_username}'" | grep -q 1; then
  desc 'Create database user'
  if sun.psql "CREATE USER ${db_username} WITH PASSWORD '${db_password}'"; then
    echo "User ${db_username} created successfully"

    desc 'Set as superuser'
    if sun.psql "ALTER USER ${db_username} WITH SUPERUSER"; then
      echo "User ${db_username} as superuser"
    else
      echo.red "Failed to set ${db_username} as superuser"
      exit 1
    fi
  else
    echo.red "Failed to create user ${db_username}"
    exit 1
  fi
fi

if ! sun.psql "SELECT 1 FROM pg_database WHERE datname='${db_database}'" | grep -q 1; then
  desc 'Create database'
  if sun.psql "CREATE DATABASE ${db_database} OWNER ${db_username}"; then
    echo "Database ${db_database} created successfully"
  else
    echo.red "Failed to create database ${db_database}"
    exit 1
  fi
fi
