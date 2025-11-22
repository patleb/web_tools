import concepts from '@@lib/ext_coffee/jest/concepts/spec_helper'

describe('Js.RoutesConcept', () => {
  concepts.with_page('routes', { root: 'ext_coffee' })

  it('should set @routes', () => {
    const routes = {
      root: '/',
      home: '/home/:lang/:page',
      next: '/page/:next/',
      prev: '/:prev/page/'
    }
    assert.equal(routes, Routes.paths)
  })

  test('#path_for', () => {
    assert.nil(Routes.path_for('404'))
    assert.equal('/', Routes.path_for('root'))
    assert.equal('/home/fr/test', Routes.path_for('home', { lang: 'fr', page: 'test' }))
    assert.equal('/page/1', Routes.path_for('next', { next: 1 }))
    assert.equal('/0/page', Routes.path_for('prev', { prev: 0 }))
    assert.equal('/?a=1', Routes.path_for('root', { a: 1 }))
  })

  test('#decode_params', () => {
    assert.equal({ a: '1', b: '2' }, Routes.decode_params('a=1&b=2'))
    assert.equal({ a: ['1', '2'] }, Routes.decode_params('a%5B%5D=1&a%5B%5D=2'))
    assert.equal({ a: { b: '1', c: '2' }, d: ['3'], e: '4' }, Routes.decode_params('a%5Bb%5D=1&a%5Bc%5D=2&d%5B%5D=3&e=4'))
  })
})
