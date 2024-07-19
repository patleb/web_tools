require './test/spec_helper'
require 'ext_ruby'

class ObjectArgs
  def self.hello(a, b, c = nil, *d, e: nil, f:, **g, &block)
    method_args(__method__) + method_keyargs(__method__)
  end

  def hello(h, i, j = nil, *k, l: nil, m:, **n, &block)
    method_args(__method__) + method_keyargs(__method__)
  end
end

class Object::ArgsTest < Minitest::Spec
  it 'should return args and keyargs' do
    assert_equal [:a, :b, :c], ObjectArgs.method_args(:hello).sort
    assert_equal [:e, :f], ObjectArgs.method_keyargs(:hello).sort
    assert_equal [:a, :b, :c, :e, :f], ObjectArgs.hello(nil, nil, f: nil).sort

    assert_equal [:h, :i, :j], ObjectArgs.new.method_args(:hello).sort
    assert_equal [:l, :m], ObjectArgs.new.method_keyargs(:hello).sort
    assert_equal [:h, :i, :j, :l, :m], ObjectArgs.new.hello(nil, nil, m: nil).sort
  end
end
