require './test/test_helper'

class ReferenceTest < Sql::TestCase
  self.migrations = {
    '20010000002220_enable_pg_counter_cache' => ExtRails::Engine.root,
    '20010000002222_enable_pg_touch' => ExtRails::Engine.root,
    '20180106225120_add_triggers_to_lib_pages' => MixPage::Engine.root,
    '20180106225130_add_triggers_to_lib_page_fields' => MixPage::Engine.root,
    '20201224095685_add_triggers_to_lib_searches' => MixSearch::Engine.root,
  }
  self.sql_root = 'ext_rails/test/migrate'

  test_sql 'reference/counter_cache'
  test_sql 'reference/touch'
end
