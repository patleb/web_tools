source 'recipes/bootstrap/timezone_locale.sh'

ntp.update
export ROLE_START=$(sun.current_time)
