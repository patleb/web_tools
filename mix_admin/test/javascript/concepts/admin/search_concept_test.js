import concepts from '@@lib/mix_admin/jest/spec_helper'

describe('Js.Admin.SearchConcept', () => {
  concepts.with_page('admin/search')

  test('.js_query_datetime[type=date]', () => {
    const search = dom.find('.js_search')
    const input = dom.find('.js_query_datetime[type=date]')
    const values = [
      ['2023-01-01', '2023-01-01'],
      ['=',          '=2023-01-01'],  // '=', '==', '!', '!=', '<', '<=', '>', '>='
      [' ',          ' =2023-01-01'], // '', ' ', '}', '|'
    ]
    for (const [value_was, value] of values) {
      input.value = '2023-01-01'
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      dom.fire('change', { target: input })
    }
  })

  test('.js_query_datetime[type=time]', () => {
    const search = dom.find('.js_search')
    const input = dom.find('.js_query_datetime[type=time]')
    const values = [
      ['23:01:01',    '23:01:01'],
      ['=',           '=23:01:01'],
      [' ',           ' =23:01:01'],
      ['2023-01-01T', '2023-01-01T23:01:01'],
      ['2023-01-01',  '2023-01-01T23:01:01'],
    ]
    for (const [value_was, value] of values) {
      input.value = '23:01:01'
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      dom.fire('change', { target: input })
    }
  })

  test('.js_query_keyword', () => {
    const search = dom.find('.js_search')
    const input = dom.find('.js_query_keyword')
    const values = [
      ['<', '<'],
      ['=', '=_true'],
      [' ', ' =_true'],
    ]
    for (const [value_was, value] of values) {
      input.set_value('_true')
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      dom.fire('change', { target: input })
    }
  })

  test('.js_query_operator', () => {
    const search = dom.find('.js_search')
    const input = dom.find('.js_query_operator')
    const values = [
      ['=', '='],
      [' ', ' ='],
    ]
    for (const [value_was, value] of values) {
      input.set_value('=')
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      dom.fire('change', { target: input })
    }
  })

  test('.js_query_or', () => {
    const search = dom.find('.js_search')
    const or = dom.find('.js_query_or')
    const values = [
      ['=',      '='],
      [' ',      ' '],
      ['{id}=1', '{id}=1|']
    ]
    for (const [value_was, value] of values) {
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      or.click()
    }
  })

  test('.js_query_and', () => {
    const search = dom.find('.js_search')
    const and = dom.find('.js_query_and')
    const values = [
      ['=',      '='],
      [' ',      ' '],
      ['{id}=1', '{id}=1 {_}']
    ]
    for (const [value_was, value] of values) {
      search.value = value_was
      dom.on_event({ 'change': () => { assert.equal(value, search.value) }})
      and.click()
    }
  })

  test('.js_query_field', () => {
    const search = dom.find('.js_search')
    const field = dom.find('.js_query_field')
    const values = [
      ['{_}',    '{_}'],
      ['{id}==', '{id}=='],
      ['',       '{id}'],
      [' ',      ' {id}'],
      ['{',      '{id'],
      ['{id}',   '{id|id}'],
      ['{id|',   '{id|'],
      ['{id}=1', '{id}=1 {id}'],
    ]
    for (const [value_was, value] of values) {
      search.value = value_was
      dom.on_event({ 'click': () => { assert.equal(value, search.value) }})
      field.click()
    }
  })
})
