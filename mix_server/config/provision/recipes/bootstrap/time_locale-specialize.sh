source 'recipes/bootstrap/time_locale.sh'

sudo service ntp stop; sudo ntpd -gq; sudo service ntp start
export ROLE_START=$(sun.start_time)
