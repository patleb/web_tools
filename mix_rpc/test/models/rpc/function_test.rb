require './test/rails_helper'

module Rpc
  class FunctionTest < ActiveSupport::TestCase
    self.file_fixture_path = Gem.root('mix_rpc').join('test/fixtures/files').to_s

    around do |test|
      MixRpc.with do |config|
        config.sql_path = Pathname.new(file_fixture_path).join('structure.sql')
        test.call
      end
    end

    it 'should parse structure.sql correctly' do
      result = {
        get_json:        [{ name: '_json', hash: true }, { name: '_float_a', array: true }, { name: '_float_a_opt', array: true }],
        get_jsonb:       [{ name: '_text' }, { name: '_bigint' }, { name: '_jsonb', hash: true }, { name: '_integer_opt' }, { name: '_text_opt' }],
        get_integer:     [{ name: '_timestamp' }, { name: '_jsonb', hash: true }],
        get_float:       [{ name: '_integer' }, { name: '_float_a', array: true }],
        get_float_a:     [{ name: '_text' }],
        get_text:        [{ name: '_text' }, { name: '_text_a_opt', array: true }, { name: '_integer_opt' }],
        get_text_a:      [{ name: '_text' }, { name: '_text_a_opt', array: true }],
        get_integer_set: [{ name: '_text' }, { name: '_bigint' }],
        get_table_rows:  [{ name: '_text' }, { name: '_bigint' }],
        healthcheck:     [],
      }.stringify_keys
      assert_equal result, Rpc::Function.parse_schema
    end
  end
end
