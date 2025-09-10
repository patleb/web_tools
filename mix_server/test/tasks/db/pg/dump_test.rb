require './test/test_helper'
require_relative './test_help'

class Db::Pg::DumpTest < Db::Pg::TestCase
  self.task_name = 'db:pg:dump'

  fixtures 'test/records'

  let(:dry_run){ true }
  let(:backup){ base_dir.join(filename) }
  let(:base_dir){ Setting[:backup_dir].join('dump') }
  let(:filename){ 'dump.pg.gz' }
  let(:split){ false }
  let(:pg_options){}
  let(:pg_dump){[
    "export PGPASSWORD=#{Setting[:db_password]};",
    'pg_dump',
    '--host', Setting[:db_host], '--port', Setting[:db_port], '--username', Setting[:db_username],
    '--verbose', '--no-owner', '--no-acl', '--clean', '--format=c', '--compress=0', pg_options,
    Setting[:db_database],
    "| pigz -p #{cores}",
    "> #{backup.expand_path.to_s}",
  ]}

  def self.test_dump(**options, &block)
    test task_name do
      raise 'must be tested in environment without stubs' if options[:physical]
      run_rake(base_dir: base_dir, **options)
      case
      when options[:csv]
        tables.each_with_index do |table, i|
          assert_equal pg_dump_csv(table, where[i] || where[0]), result[i].squish
        end
      when options[:split]
        assert_equal pg_dump_split, result.first.squish
      else
        assert_equal pg_dump.compact.join(' '), result.first.squish
      end
      instance_eval(&block) if block_given?
    end
  end
  def self.xtest_dump(**); end

  test_dump

  context 'with version' do
    let(:filename){ "dump-#{version}.pg.gz" }

    test_dump version: true

    context 'with rotate' do
      let(:filename){ "dump_#{today}-#{version}.pg.gz" }

      before do
        base_dir.mkdir_p
        1.day.ago.rotations.each do |date|
          base_dir.join("dump_#{date}-#{version}.pg.gz").touch
        end
        base_dir.join("dump_#{today}-aaaaaaa.pg.gz").touch
      end

      after do
        FileUtils.rm_rf(base_dir)
      end

      test_dump version: true, rotate: true do
        assert_equal dates, Time.current.rotations - [today]
      end

      context 'as real' do
        let(:dry_run){ false }
        let(:filename){ "dump_#{today}-#{version}.pg.gz-000000" }

        test task_name do
          options = {
            version: true,
            rotate: true,
            split: true,
            md5: true,
            excludes: 'schema_migrations,ar_internal_metadata',
          }
          run_rake(base_dir: base_dir, **options)
          assert_equal [today] + dates, Time.current.rotations
          assert_equal false, backup.empty?
          assert_equal false, base_dir.join("#{filename}.md5").empty?
        end
      end
    end
  end

  context 'with includes and excludes' do
    let(:pg_options){[
      "--table='test_*'",
      "--table='test_*_id_seq'",
      "--exclude-table='test_related_records'",
      "--exclude-table='test_related_records_id_seq'",
    ].join(' ')}

    test_dump includes: ['test_*'], excludes: ['test_related_records']
  end

  context 'with split' do
    let(:split){ Setting[:backup_split_size] }

    test_dump split: true
  end

  context 'as csv' do
    let(:tables){ ['test_records', 'test_related_records'] }
    let(:where){ ['id >= 1'] }

    test_dump csv: true, includes: 'test_records,test_related_records', where: 'id >= 1'

    context 'with wheres' do
      let(:where){ ['id > 0', 'id >= 1'] }

      test_dump csv: true, includes: 'test_records,test_related_records', where: 'id > 0,id >= 1'
    end

    context 'as real' do
      let(:dry_run){ false }
      let(:filename){ 'dump~test_records.csv' }

      after do
        FileUtils.rm_rf(base_dir)
      end

      test task_name do
        run_rake(base_dir: base_dir, csv: true, includes: 'test_records', where: 'id > 1', compress: false, pg_options: 'HEADER')
        assert_equal false, backup.empty?
      end
    end
  end

  private

  def pg_dump_csv(table, where)
    backup = Pathname.new(base_dir).join("dump~#{table}.csv.gz").expand_path.to_s
    <<-CMD.squish
      psql --quiet --tuples-only --no-align --echo-errors
        -c "\\COPY (SELECT * FROM #{table} WHERE #{where}) TO PROGRAM 'pigz -p #{cores} > #{backup}' DELIMITER ',' CSV ;"
        #{Setting.db_url}
    CMD
  end

  def pg_dump_split
    pg_dump[0..-2].compact.join(' ') << " | split -d -a 6 -b #{split} - #{backup.expand_path.to_s}-"
  end

  def cores
    @cores ||= (cores = (Etc.nprocessors / 2.0).ceil) > 32 ? 32 : cores
  end

  def dates
    base_dir.glob('*.pg.gz').map{ |path| path.basename.to_s[/\d{4}_\d{2}_\d{2}/] }.sort.reverse
  end
end
