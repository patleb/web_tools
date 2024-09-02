require './test/test_helper'
require Gem.root('mix_server').join('test/fixtures/files/log/auth.rb').to_s

module LogLines
  class AuthTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    test '.parse' do
      file = file_fixture('log/auth.log')

      log = Log.create! server: Server.current, path: file.to_s
      file.each_line.with_index do |line, i|
        assert_equal AUTH_EXPECTATIONS[i], LogLines::Auth.parse(log, line, mtime: file.mtime)
      end
    end
  end
end
