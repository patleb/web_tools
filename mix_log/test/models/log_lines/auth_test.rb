require './test/rails_helper'

module LogLines
  class AuthTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      require Gem.root('mix_log').join('test/fixtures/files/log/auth.rb').to_s
      file = file_fixture('log/auth.log')

      file.each_line.with_index do |line, i|
        assert_equal AUTH_EXPECTATIONS[i], LogLines::Auth.parse(nil, line, mtime: file.mtime)
      end
    end
  end
end
