Commands:

    $ sudo osqueryd --ephemeral --disable_database --disable_logging
    $ sudo rm -rf ./tmp/osquery/osquery.db
    $ sudo rm -rf ./tmp/osquery/* && sudo osqueryd && sudo chmod +r ./tmp/osquery/*.log
    $ sudo osqueryi
