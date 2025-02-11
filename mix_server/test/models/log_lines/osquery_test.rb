require './test/test_helper'

module LogLines
  class OsqueryTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    test '.parse' do
      MixServer::Logs.with do |config|
        log_path = config.log_path(:osquery, 'osqueryd.results')
        config.available_paths = [log_path]

        file = file_fixture('log/osquery/osqueryd.results.log')

        log = Log.create! server: Server.current, path: file.to_s
        count, filtered, info, files, sockets = 0, 0, 0, 0, 0
        file.each_line do |line|
          line = LogLines::Osquery.parse(log, line)
          case line.dig(:json_data, :name)
          when 'osquery_info'  then info += 1
          when 'file_events'   then files += 1
          when 'socket_events' then sockets += 1
          end
          filtered += 1 if line[:filtered]
          count += 1
        end
        assert_equal 7, count
        assert_equal 1, filtered
        assert_equal 4, info
        assert_equal 1, files
        assert_equal 1, sockets
      end
    end
  end
end
