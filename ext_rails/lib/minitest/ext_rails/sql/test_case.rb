require 'sql_query'

module Sql
  class TestCase < ActiveSupport::TestCase
    MIGRATIONS_DIRNAME = 'db/migrate'.freeze

    class_attribute :migrations_root, :migrations, :adapter, :sql_root

    self.use_transactional_tests = false
    self.migrations_root = Rails.root
    self.migrations = []
    self.adapter = ActiveRecord::Base
    self.sql_root = 'test/migrate'

    delegate :connection, to: :adapter

    def self.test_sql(suite_name, **options)
      it "should run sql script for suite: #{suite_name.full_underscore}" do
        TestQuery.new(suite_name, **options).run_suite
      end
    end

    class TestQuery < ::SqlQuery
      include Minitest::Assertions

      def initialize(...)
        super
        @name = @sql_filename.to_s.gsub(/\W/, '_')
      end

      def assertions
        $test.assertions
      end

      def assertions=(value)
        $test.assertions = value
      end

      def setup
        @output << <<~SQL
          CREATE OR REPLACE FUNCTION test_assert_succeeded() RETURNS VOID AS $$
          BEGIN
            PERFORM test_autonomous('INSERT INTO test_asserts (id) VALUES (DEFAULT);');
          END;
          $$ LANGUAGE plpgsql;

          CREATE OR REPLACE FUNCTION test_assert_true(message VARCHAR, condition BOOLEAN) RETURNS VOID AS $$
          BEGIN
            PERFORM test_assertTrue(message, condition);
            PERFORM test_assert_succeeded();
          end;
          $$ LANGUAGE plpgsql SET search_path FROM CURRENT IMMUTABLE;

          CREATE OR REPLACE FUNCTION test_assert_true(condition BOOLEAN) RETURNS VOID AS $$
          BEGIN
            PERFORM test_assertTrue(condition);
            PERFORM test_assert_succeeded();
          end;
          $$ LANGUAGE plpgsql SET search_path FROM CURRENT IMMUTABLE;

          CREATE OR REPLACE FUNCTION test_assert_not_null(VARCHAR, ANYELEMENT) RETURNS VOID AS $$
          BEGIN
            PERFORM test_assertNotNull($1, $2);
            PERFORM test_assert_succeeded();
          end;
          $$ LANGUAGE plpgsql SET search_path FROM CURRENT IMMUTABLE;

          CREATE OR REPLACE FUNCTION test_assert_null(VARCHAR, ANYELEMENT) RETURNS VOID AS $$
          BEGIN
            PERFORM test_assertNull($1, $2);
            PERFORM test_assert_succeeded();
          end;
          $$ LANGUAGE plpgsql SET search_path FROM CURRENT IMMUTABLE;

          CREATE OR REPLACE FUNCTION test_setup_#{@name}() RETURNS VOID AS $$
          BEGIN
            IF EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'test_teardown_#{@name}') THEN
              SET client_min_messages TO WARNING;
              BEGIN
                PERFORM test_teardown_#{@name}();
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
              SET client_min_messages TO DEFAULT;
            END IF;
            CREATE TABLE test_asserts (
              id SERIAL
            );
        SQL

        yield

        @output << <<~SQL
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def teardown
        @output << <<~SQL
          CREATE OR REPLACE FUNCTION test_teardown_#{@name}() RETURNS VOID AS $$
          BEGIN
            RAISE NOTICE '[%] [%] asserts in test suite "#{@name}"', LOCALTIME, (SELECT COUNT(*) FROM test_asserts);
            DROP TABLE IF EXISTS test_asserts;
        SQL

        yield

        @output << <<~SQL
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end

      def sql
        @output ||= begin
          @output = ''
          @virtual_path = file_path.delete_suffix('.sql.erb')
          ERB.new(File.read(file_path), nil, nil, "@output").result(binding)
        end
      end

      def partial(name)
        previous_path = @virtual_path
        result = ERB.new(File.read(partial_path(name))).result(binding)
        result.sub! /CREATE OR REPLACE FUNCTION \w+\(\) RETURNS VOID AS \$\$\s+DECLARE\s+(BEGIN\s+)?/i, ''
        result.sub /(\s+BEGIN)?\s+END;\s+\$\$ LANGUAGE plpgsql;/i, ''
      ensure
        @virtual_path = previous_path
      end

      def partial_path(name)
        partial_name = "#{name.sub(%r{(/?)(\w+)$}, '\1_\2')}.sql.erb"
        if name.exclude?('/') && File.exist?("#{File.dirname(@virtual_path)}/#{partial_name}")
          tmp_path = File.dirname(@virtual_path)
        elsif @sql_file_path.present?
          tmp_path = @sql_file_path
        else
          root = defined?(Rails.root) ? Rails.root.to_s : Dir.pwd
          tmp_path = "#{root}#{self.class.config.path}"
        end
        @virtual_path = "#{tmp_path}/#{name}"
        [tmp_path, partial_name].join('/')
      end

      def prepared_for_logs
        script = sql.strip_sql
        unless script.sub! /(CREATE OR REPLACE FUNCTION )test_suite(\(\) RETURNS VOID AS \$\$)/i, "\\1test_case_#{@name}\\2"
          raise 'test case method must have this exact signature: `CREATE OR REPLACE FUNCTION test_suite() RETURNS VOID AS $$`'
        end
        script
      end

      def run_suite
        execute
        connection.exec_query("SELECT * FROM test_run_suite('#{@name}')").entries.each do |entry|
          assert_equal 'OK', entry['error_message']
        end
      end
    end

    before(:all) do
      drop_procedures
      run_migrations

      TestQuery.configure do |config|
        config.path = sql_root.start_with?('/') ? sql_root : "/#{sql_root}"
      end
    end

    private

    def drop_procedures
      procedures = connection.select_values(<<-SQL)
        SELECT proname FROM pg_proc
        WHERE proname LIKE 'test\_setup\_%'
          OR  proname LIKE 'test\_precondition\_%'
          OR  proname LIKE 'test\_case\_%'
          OR  proname LIKE 'test\_postcondition\_%'
          OR  proname LIKE 'test\_teardown\_%'
          OR  proname LIKE 'test\_assert\_%'
      SQL

      procedures.each do |procedure|
        connection.exec_query "DROP FUNCTION IF EXISTS #{procedure}"
      end
    end

    def run_migrations
      migrations = self.migrations
      migrations = migrations.each_with_object({}){ |name, memo| memo[name] = migrations_root } if migrations.is_a? Array
      migrations = migrations.each_with_object([]) do |(name, root), memo|
        require root.join(MIGRATIONS_DIRNAME, name)

        number, name = name.split('_', 2)
        memo << [number, name.camelize.constantize.new]
      end.sort_by(&:first).map(&:last)

      migrations.reverse.each(&:migrate.with(:down))
      migrations.each(&:migrate.with(:up))
    end
  end
end
