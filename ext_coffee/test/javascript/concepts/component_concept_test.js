import concepts from '@@lib/ext_coffee/jest/concepts/spec_helper'
require('@@lib/ext_coffee/jest/elements/banner_element')
require('@@lib/ext_coffee/jest/elements/card_element')

describe('Js.ComponentConcept', () => {
  concepts.with_page('component', { root: 'ext_coffee', before: () => {
    Js.Concepts.add_concept('Js.TagConcept')
    Tag.define('h1', 'h2')
  }})

  it('should render elements', () => {
    const banner = dom.find(`${Js.Component.ELEMENTS}[data-element=banner]:not([data-turbolinks-permanent],[data-static])`)
    const banner_persistent = dom.find(`${Js.Component.ELEMENTS}[data-element=banner][data-turbolinks-permanent]`)
    const banner_static = dom.find(`${Js.Component.ELEMENTS}[data-element=banner][data-static]`)
    const banner_card = dom.find(`${Js.Component.ELEMENTS}[data-element=banner][data-scope=card]`)
    const card = dom.find(`${Js.Component.ELEMENTS}[data-element=card]`)
    const card_element = Js.Component.elements[card.dataset.uid]
    const input = card.find('input')
    assert.html_equal('<div><h1>Persistent World!</h1></div>', banner_persistent.innerHTML)
    assert.html_equal('<div><h1>Hello World!</h1></div>', banner.innerHTML)
    assert.html_equal(
      `<div>
        <h2>Today</h2>
        <ul><li>Player 1</li><li>Player 2</li></ul>
        <input type="text" value="Input name" data-bind="name">
      </div>`,
      card.innerHTML
    )
    input.value = 'New name'
    dom.fire('input', { target: input })
    assert.html_equal('<div><h1>Today</h1></div>', banner_card.innerHTML)
    assert.equal('New name', input.get_value())
    assert.false(card_element._stale)
    assert.html_equal(
      `<div>
        <h2>Today</h2>
        <ul><li>Player 1</li><li>Player 2</li></ul>
        <input type="text" value="Input name" data-bind="name">
      </div>`,
      card.innerHTML
    )
    Js.Storage.set({ banner: 'Tomorrow' }, { scope: card_element._scope })
    assert.html_equal(
      `<div>
        <h2>Tomorrow</h2>
        <ul><li>Player 1</li><li>Player 2</li></ul>
        <input type="text" value="Input name" data-bind="name">
      </div>`,
      card.innerHTML
    )
    Js.Storage.set({ banner: 'Again World!' }, { permanent: true })
    Js.Storage.set({ banner: 'New World!' })
    assert.html_equal('<div><h1>Again World!</h1></div>', banner_persistent.innerHTML)
    assert.html_equal('<div><h1>New World!</h1></div>', banner.innerHTML)
    assert.html_equal('<div><h1>Header</h1></div>', banner_static.innerHTML)
  })

  it('should fire change event', () => {
    assert.total(1)
    dom.on_event({ [Js.Component.RENDER]: ({ detail: { elements }}) => {
      assert.equal(1, elements.keys_length) // BannerElement
    }})
    Js.Storage.set({ banner: 'changed' })
  })

  it('should allow in-context #events', () => {
    assert.total(1)
    const card = dom.find(`${Js.Component.ELEMENTS}[data-element=card]`)
    dom.on_event({ 'click': (event) => {
      assert.same(card, event.element._node)
    }})
    card.find('input').click()
  })

  it('should update output texts when input changes', () => {
    assert.total(2)
    let value = new Date(Date.parse('2013-01-01'))
    const label = dom.find('#label')
    const input = dom.find(Js.TagConcept.INPUTS)
    const output = dom.find('#output')
    dom.on_event({ 'input': () => {
      assert.equal(label.innerHTML, value.safe_text().toString())
      assert.equal(output.innerHTML, value.strftime('%Y-%m-%d %H:%M:%S %Z'))
    }})
    input.value = value.safe_text()
    dom.fire('input', { target: input })
  })
})
