require './test/rails_helper'
require Gem.root('mix_log').join('test/fixtures/files/log/test.rb').to_s

module LogLines
  class AppTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/test.log')

      previous = nil
      file.each_line.with_index do |line, i|
        line = LogLines::App.parse(nil, line, mtime: file.mtime, previous: previous)
        assert_equal APP_EXPECTATIONS[i], line
        previous = line
      end
    end
  end
end
