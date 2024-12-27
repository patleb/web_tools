require './test/spec_helper'

class HashTest < Minitest::TestCase
  let(:first){ { a: 1, b: [1], c: { d: [3], e: { f: [5] } } } }
  let(:other){ { a: 2, b: [2], c: { d: [4], e: { f: [6] } } } }
  let(:complex){ { a: 0, 'b' => 1.0, '3rd Key' => Time.utc(2000), true => false, D: nil } }

  test '#union, #union!' do
    expected = { a: 2, b: [1, 2], c: { d: [4], e: { f: [6] } } }
    assert_equal expected, first.union(other)
    first.union! other
    assert_equal expected, first
  end

  test '#deep_union, #deep_union!' do
    expected = { a: 2, b: [1, 2], c: { d: [3, 4], e: { f: [5, 6] } } }
    assert_equal expected, first.deep_union(other)
    first.deep_union! other
    assert_equal expected, first
  end

  test '#pretty_hash, #pretty_hash!' do
    assert_equal nil, {}.pretty_hash
    assert_equal '{a: 1, b: [1], c: {d: [3], e: {f: [5]}}}', first.pretty_hash
    assert_equal '{a: 0, b: 1.0, "3rd Key"=>"2000-01-01T00:00:00Z", true=>false, D: nil}', complex.pretty_hash
    assert_equal '{"3rd Key"=>"2000-01-01T00:00:00Z", D: nil, a: 0, b: 1.0, true=>false}', complex.sort_by{ |k, _| k.to_s }.reverse.to_h.pretty_hash!
  end

  test 'HashWithKeywordAccess#convert_key' do
    assert_equal({ a: 0, b: 1.0, :'3rd Key' => Time.utc(2000), true => false, D: nil }, complex.to_hwka)
    assert_equal([:a, :b, :'3rd Key', :''], { a: 1, 'b' => 2, '3rd Key' => 3, '' => nil }.to_hwka.keys)
  end
end
