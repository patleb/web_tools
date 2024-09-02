require './test/test_helper'
require Gem.root('mix_server').join('test/fixtures/files/log/postgresql/postgresql.rb').to_s

module LogLines
  class PostgresqlTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_server').join('test/fixtures/files').to_s

    test '.parse' do
      file = file_fixture('log/postgresql/postgresql-14-main.log')

      log = Log.create! server: Server.current, path: file.to_s
      file.each_line.with_index do |line, i|
        assert_equal POSTGRESQL_EXPECTATIONS[i], LogLines::Postgresql.parse(log, line, mtime: file.mtime)
      end
    end

    test 'version' do
      yml = YAML.safe_load(Gem.root('mix_server').join('config/settings.yml').read)
      assert_equal 4, Setting[:db_port] % 10
      assert_equal 14, yml.dig('shared', 'postgres'), <<~MSG
        Postgres version has changed, do not forget to compare error msg
        from the official github repo to those in LogLines::Postgresql regexes.
      MSG
    end
  end
end
