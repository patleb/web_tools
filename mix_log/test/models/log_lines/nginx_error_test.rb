require './test/rails_helper'
require Gem.root('mix_log').join('test/fixtures/files/log/nginx/web_tools.error.rb').to_s

module LogLines
  class NginxErrorTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/nginx/web_tools.error.log.0')

      log = Log.create! server: Server.current, path: file.to_s.delete_suffix('.0')
      previous = nil
      file.each_line.with_index do |line, i|
        line = LogLines::NginxError.parse(log, line, mtime: file.mtime, previous: previous)
        # puts line
        # assert_equal ERROR_EXPECTATIONS[i], LogLines::NginxError.parse(log, line, mtime: file.mtime)
        previous = line
      end
    end
  end
end
