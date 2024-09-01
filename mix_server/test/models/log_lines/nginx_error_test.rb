require './test/test_helper'
require Gem.root('mix_server').join('test/fixtures/files/log/nginx/web_tools_test.error.rb').to_s

module LogLines
  class NginxErrorTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    test '.parse' do
      file = file_fixture('log/nginx/web_tools_test.error.log.0')
      mtime = Time.utc(2022,7,27,10,9,54)

      log = Log.create! server: Server.current, path: file.to_s.delete_suffix('.0')
      previous = nil
      file.each_line.with_index do |line, i|
        line = LogLines::NginxError.parse(log, line, mtime: mtime, previous: previous)
        assert_equal ERROR_EXPECTATIONS[i], line
        previous = line
      end
    end
  end
end
