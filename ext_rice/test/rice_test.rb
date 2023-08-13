require './ext_rice/test/spec_helper'

module ExtRice
  class RiceTest < Rice::TestCase
    test_yml 'ext_rice', fixture_yml: true
    test_cpp 'ext_rice'
  end
end
