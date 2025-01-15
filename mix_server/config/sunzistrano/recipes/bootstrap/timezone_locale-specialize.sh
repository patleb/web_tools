source 'recipes/bootstrap/timezone_locale.sh'

sudo service ntp stop; sudo ntpd -gq; sudo service ntp start
export ROLE_START=$(sun.current_time)
