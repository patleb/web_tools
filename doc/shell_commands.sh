# consult concatenated logs in reverse order
zcat -f -- staging.log* | tac

# sun_provision.log
sudo cat sun_provision.log | grep -A 1 -B 1 -e '\(Recipe\|Done\) \['

# osquery
sudo osqueryd --ephemeral --disable_database --disable_logging
sudo rm -rf ./tmp/osquery/osquery.db
sudo rm -rf ./tmp/osquery/* && sudo osqueryd && sudo chmod +r ./tmp/osquery/*.log
sudo osqueryi
