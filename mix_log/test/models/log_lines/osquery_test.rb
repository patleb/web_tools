require './test/rails_helper'

module LogLines
  class OsqueryTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/osquery/osqueryd.results.log')

      count, info, files, sockets = 0, 0, 0, 0
      file.each_line do |line|
        line = LogLines::Osquery.parse(nil, line)
        case line.dig(:json_data, :name)
        when 'osquery_info'  then info += 1
        when 'file_events'   then files += 1
        when 'socket_events' then sockets += 1
        end
        count += 1
      end
      assert_equal 7, count
      assert_equal 4, info
      assert_equal 1, files
      assert_equal 1, sockets
    end
  end
end
