require './ext_rice/test/spec_helper'

module ExtRice
  class RiceTest < Rice::TestCase
    test_yml 'ext_rice', yml_path: file_fixture_path('ext_rice').join('rice.yml')
    test_cpp 'ext_rice'
  end
end
