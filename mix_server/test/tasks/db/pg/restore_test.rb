require './test/test_helper'
require_relative './test_help'

class Db::Pg::RestoreTest < Db::Pg::TestCase
  self.task_name = 'db:pg:restore'
  self.use_transactional_tests = false

  let(:dry_run){ true }
  let(:backup){ base_dir.join(filename).expand_path }
  let(:base_dir){ Setting[:backup_dir].join('restore') }
  let(:filename){ 'dump.pg.gz-*' }
  let(:tables){}
  let(:pg_options){}
  let(:pg_restore){[
    "export PGPASSWORD=#{Setting[:db_password]};",
    "cat #{backup}",
    "| unpigz -c",
    '| pg_restore',
    '--host', Setting[:db_host], '--port', Setting[:db_port], '--username', Setting[:db_username],
    '--verbose', '--no-owner', '--no-acl', pg_options, tables,
    '--dbname', Setting[:db_database],
  ].compact.join(' ')}

  def self.test_restore(md5: false, **options, &block)
    test task_name do
      if md5
        assert_output /checked/, /md5sum/ do
          run_rake(path: backup, **options)
        end
      else
        run_rake(path: backup, md5: false, **options)
      end
      instance_eval(&block) if block_given?
    end
  end
  def self.xtest_restore(**); end

  before(:all) do
    Test::MuchRecord.insert_all! (1..22).map{ |i| { name: "Name #{i}" } }
    let(:dry_run, false) do
      run_rake as: 'db:pg:dump', base_dir: base_dir, split: true, md5: true
    end
    Test::MuchRecord._drop_all_partitions!
  end

  test_restore do
    assert_equal pg_restore, result.first.squish
  end

  context 'with md5' do
    test_restore md5: true do
      assert_equal pg_restore, result.first.squish
    end

    context 'as real' do
      let(:dry_run){ false }

      before do
        assert_equal 0, Test::MuchRecord.partitions.size
        assert_equal 0, Test::MuchRecord.count
      end

      test_restore md5: true, data_only: true, append: true, includes: 'test_much_records*' do
        assert_equal 5, Test::MuchRecord.partitions.size
        assert_equal 22, Test::MuchRecord.count
        Test::MuchRecord._drop_all_partitions!
      end
    end
  end

  test '::MATCHER' do
    assert_matcher 'dump.tar',                    table: nil,            type: 'tar', compress: nil,   split: nil
    assert_matcher 'dump~test_records.csv',       table: 'test_records', type: 'csv', compress: nil,   split: nil
    assert_matcher 'dump~test_records.csv-*',     table: 'test_records', type: 'csv', compress: nil,   split: '-*'
    assert_matcher 'dump~test_records.csv.gz',    table: 'test_records', type: 'csv', compress: '.gz', split: nil
    assert_matcher 'dump~test_records.csv.gz-*',  table: 'test_records', type: 'csv', compress: '.gz', split: '-*'
    assert_matcher 'dump.pg',                     table: nil,            type: 'pg',  compress: nil,   split: nil
    assert_matcher 'dump.pg.gz',                  table: nil,            type: 'pg',  compress: '.gz', split: nil
    assert_matcher "dump_#{today}-aaaaaaa.pg.gz", table: nil,            type: 'pg',  compress: '.gz', split: nil
    assert_matcher "dump-#{version}.pg.gz-*",     table: nil,            type: 'pg',  compress: '.gz', split: '-*'
  end

  context 'with includes and excludes' do
    let(:tables){ "--table='test_records' --table='test_records_id_seq'" }

    test_restore includes: ['test_*'], excludes: ['test_related_records', 'test_much_records*', 'test_time_series'] do
      assert_equal pg_restore, result.first.squish
    end
  end

  context 'with data_only' do
    let(:pg_options){ '--disable-triggers --data-only' }

    test_restore data_only: true do
      assert_match /psql[\w -]+-c "TRUNCATE TABLE ONLY[\w, ]+test_much_records[\w, ]+RESTART IDENTITY CASCADE;"/, result.first
      assert_equal pg_restore, result.second.squish
      assert_equal 5, Test::MuchRecord.partitions.size
      Test::MuchRecord._drop_all_partitions!
    end

    context 'with append' do
      let(:tables){ "--table='test_records' --table='test_records_id_seq'" }

      test_restore data_only: true, append: true, includes: 'test_records' do
        assert_equal pg_restore, result.first.squish
        assert_equal 0, Test::MuchRecord.partitions.size
      end
    end
  end

  context 'with staged' do
    test_restore staged: true do
      %w(pre-data data post-data).each_with_index do |section, i|
        assert_equal "#{pg_restore} --section=#{section}", result[i].squish
      end
    end
  end

  context 'as csv' do
    let(:filename){ 'dump~test_records.csv.gz-*' }

    test_restore do
      assert_equal <<-CMD.squish, result.first.squish
        psql --quiet --tuples-only --no-align --echo-errors
          -c "\\COPY test_records FROM PROGRAM 'cat #{backup} | unpigz -c' CSV;"
          #{Setting.db_url}
      CMD
    end
  end

  private

  def assert_matcher(filename, table:, type:, compress:, split:)
    assert_equal [table, type, compress, split], base_dir.join(filename).basename.to_s.match(Db::Pg::Restore::MATCHER).captures
  end
end
