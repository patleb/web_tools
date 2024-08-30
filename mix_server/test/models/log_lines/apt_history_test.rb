require './test/test_helper'

module LogLines
  class AptHistoryTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    test '.parse' do
      file = file_fixture('log/apt/history.log')

      log = Log.create! server: Server.current, path: file.to_s
      previous, start, filtered, anchored = nil, 0, 0, 0
      file.each_line.with_index do |line, i|
        line =  LogLines::AptHistory.parse(log, line, mtime: file.mtime, previous: previous)
        case
        when line[:anchored] then anchored += 1
        when line[:filtered] then filtered += 1
        else start += 1
        end
        previous = line
      end
      assert_equal 18, start
      assert_equal 18, filtered
      assert_equal 64, anchored
    end
  end
end
