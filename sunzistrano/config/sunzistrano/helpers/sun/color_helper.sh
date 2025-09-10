echo.started() {
  echo.cyan "[$(sun.timestamp)] $@"
}

echo.success() {
  echo.green "[$(sun.timestamp)] $@"
}

echo.failure() {
  echo.red "[$(sun.timestamp)] $@"
}

echo.warning() {
  echo.yellow "[$(sun.timestamp)] $@"
}

echo.red() {
  sun.color "0;31" "$@"
}

echo.green() {
  sun.color "0;32" "$@"
}

echo.yellow() {
  sun.color "0;33" "$@"
}

echo.blue() {
  sun.color "0;34" "$@"
}

echo.magenta() {
  sun.color "0;35" "$@"
}

echo.cyan() {
  sun.color "0;36" "$@"
}

echo.lightgray() {
  sun.color "0;37" "$@"
}

echo.darkgray() {
  sun.color "1;30" "$@"
}

echo.lightred() {
  sun.color "1;31" "$@"
}

echo.lightgreen() {
  sun.color "1;32" "$@"
}

echo.lightyellow() {
  sun.color "1;33" "$@"
}

echo.lightblue() {
  sun.color "1;34" "$@"
}

echo.lightmagenta() {
  sun.color "1;35" "$@"
}

echo.lightcyan() {
  sun.color "1;36" "$@"
}

echo.white() {
  sun.color "1;37" "$@"
}

sun.color() {
  local color="$1"
  local options=$2
  set +u; local text=$3; set -u
  if [[ -z "${text}" ]]; then
    text=$options
    options=''
  fi
  if [[ -v NO_COLOR && $NO_COLOR == true ]]; then
    echo -e $options "${text}"
  else
    echo -e $options "\e[${color}m${text}\e[0m"
  fi
}
