PASSENGER_RESTART=${PASSENGER_RESTART:-true}

if [[ "$PASSENGER_RESTART" == true ]]; then
  desc 'Restart your Passenger application'
  passenger.restart
fi
