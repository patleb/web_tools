require './test/rails_helper'
require Gem.root('mix_log').join('test/fixtures/files/log/postgresql/postgresql.rb').to_s

module LogLines
  class PostgresqlTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_log').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/postgresql/postgresql-13-main.log')

      file.each_line.with_index do |line, i|
        assert_equal POSTGRESQL_EXPECTATIONS[i], LogLines::Postgresql.parse(nil, line, mtime: file.mtime)
      end
    end
  end
end
