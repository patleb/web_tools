import concepts from './spec_helper'

describe('Js.AdminConcept', () => {
  concepts.with_page('admin', false)

  test('#toggle_bulk_form', () => {
    const toggle = Js.AdminConcept.bulk_toggles.first()
    const checkbox = Js.AdminConcept.bulk_checkboxes.first()
    dom.on_event({ 'change': () => {
      assert.true(Js.AdminConcept.bulk_checkboxes.all(checkbox => checkbox.get_value()))
      assert.true(Js.AdminConcept.bulk_buttons.none(button => button.hasAttribute('disabled')))
    }})
    toggle.click()
    dom.on_event({ 'change': () => {
      assert.true(Js.AdminConcept.bulk_checkboxes.none(checkbox => checkbox.get_value()))
      assert.true(Js.AdminConcept.bulk_buttons.all(button => button.hasAttribute('disabled')))
    }})
    toggle.click()
    // all checked
    Js.AdminConcept.bulk_checkboxes.each(checkbox => checkbox.click())
    assert.true(toggle.get_value())
    assert.true(Js.AdminConcept.bulk_buttons.none(button => button.hasAttribute('disabled')))
    // one unchecked
    checkbox.click()
    assert.false(checkbox.get_value())
    assert.true(toggle.get_value())
    assert.true(Js.AdminConcept.bulk_buttons.none(button => button.hasAttribute('disabled')))
    // none checked
    checkbox.click()
    Js.AdminConcept.bulk_checkboxes.each(checkbox => checkbox.click())
    assert.false(toggle.get_value())
    assert.true(Js.AdminConcept.bulk_buttons.all(button => button.hasAttribute('disabled')))
    // one checked
    checkbox.click()
    assert.true(checkbox.get_value())
    assert.false(toggle.get_value())
    assert.true(Js.AdminConcept.bulk_buttons.none(button => button.hasAttribute('disabled')))
  })
})
