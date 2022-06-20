import concepts from './spec_helper'

describe('Js.ComponentConcept', () => {
  concepts.with_page('component')

  it('should render elements', () => {
    const banner = dom.$0(`${Js.Component.ELEMENTS}[data-element=banner]`)
    const card = dom.$0(`${Js.Component.ELEMENTS}[data-element=card]`)
    const card_element = Js.Component.elements[card.dataset.uid]
    const input = card.$0('input')
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
    assert.html_equal(
      `<div>
        <h2>Today</h2>
        <ul><li>Player 1</li><li>Player 2</li></ul>
        <input type="text" value="New name" data-bind="name">
      </div>`,
      card.innerHTML
    )
    Js.Storage.set({ banner: 'Tomorrow' }, { scope: card_element.uid })
    assert.html_equal(
      `<div>
        <h2>Tomorrow</h2>
        <ul><li>Player 1</li><li>Player 2</li></ul>
        <input type="text" value="New name" data-bind="name">
      </div>`,
      card.innerHTML
    )
    Js.Storage.set({ banner: 'New World!' })
    assert.html_equal('<div><h1>New World!</h1></div>', banner.innerHTML)
  })
})
