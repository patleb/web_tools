require './test/test_helper'

class ActionDispatch::Routing::Mapper::ResourcesTest < ActionDispatch::IntegrationTest
  test '#simple_resources' do
    assert_routing({ path: '/test/records' },                          controller: 'test/records', action: 'index')
    assert_routing({ path: '/test/records/new' },                      controller: 'test/records', action: 'new')
    assert_routing({ path: '/test/records/new', method: 'post' },      controller: 'test/records', action: 'create')
    assert_routing({ path: '/test/records/1' },                        controller: 'test/records', action: 'show', id: '1')
    assert_routing({ path: '/test/records/1/edit' },                   controller: 'test/records', action: 'edit', id: '1')
    assert_routing({ path: '/test/records/1/edit', method: 'post' },   controller: 'test/records', action: 'update', id: '1')
    assert_routing({ path: '/test/records/1/delete' },                 controller: 'test/records', action: 'delete', id: '1')
    assert_routing({ path: '/test/records/1/delete', method: 'post' }, controller: 'test/records', action: 'destroy', id: '1')
  end
end
