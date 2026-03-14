source 'recipes/bootstrap/timezone_locale.sh'

sun.ntp_update
export ROLE_START=$(sun.current_time)
