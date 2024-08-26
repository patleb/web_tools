require './test/rails_helper'
require Gem.root('mix_server').join('test/fixtures/files/log/postgresql/postgresql.rb').to_s

module LogLines
  class PostgresqlTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    it 'should parse correctly each line' do
      file = file_fixture('log/postgresql/postgresql-13-main.log')

      log = Log.create! server: Server.current, path: file.to_s
      Log.create! server: log.server, log_lines_type: 'LogLines::Host'
      file.each_line.with_index do |line, i|
        assert_equal POSTGRESQL_EXPECTATIONS[i], LogLines::Postgresql.parse(log, line, mtime: file.mtime)
      end
    end
  end
end
