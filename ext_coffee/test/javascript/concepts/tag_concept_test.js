import concepts from '@@lib/ext_coffee/jest/concepts/spec_helper'

describe('Js.TagConcept', () => {
  const values = ['Prev', 'Next'].map(text => `<div>${text}</div>`)
  const safe_values = values.map(v => v.html_safe(true))

  beforeAll(async () => {
    concepts.load_document()
    await tick()
  })

  it('should define tags', () => {
    Tag.define('blockquote')
    assert.equal(
      '<blockquote data-href="#">HOME</blockquote>'.html_safe(true),
      blockquote_({ 'data-href': '#' }, () => 'HOME')
    )
  })

  describe('#h_', () => {
    it('should join nodes and respect #html_safe value', () => {
      let expected = [[safe_values.first()], safe_values]
      expected.each((expect) => {
        let actual = h_(...expect)
        assert.equal(expect.join(' ').html_safe(true), actual)
        assert.true(actual.html_safe())
      })
      expected = [[values.first()], values]
      expected.each((expect) => {
        let actual = h_(...expect)
        assert.equal(expect.join(' ').safe_text(), actual)
        assert.true(actual.html_safe())
      })
      assert.html_equal(
        '<div>Hello</div><div>World!</div>'.html_safe(true),
        h_(div$('Hello'), div_('World!'), null)
      )
    })

    it('should allow to pass function as argument', () => {
      assert.equal('HOME'.html_safe(true), h_(() => 'HOME'))
      assert.equal('HOME'.html_safe(true), h_(() => ['HOME']))
    })
  })

  describe('#if_', () => {
    it('should print if condition is true', () => {
      assert.equal(safe_values.first(), if_(true, safe_values.first()))
      assert.equal(''.html_safe(true),  if_(false, values.first()))
    })
  })

  describe('#unless_', () => {
    it('should print unless condition is true', () => {
      assert.equal(safe_values.first(), unless_(false, safe_values.first()))
      assert.equal(''.html_safe(true),  unless_(true, safe_values.first()))
    })
  })

  describe('#with_tag', () => {
    it('should prefer text option, then first arg, then last arg', () => {
      assert.equal('<div>option</div>'.html_safe(true),         div_('text', { text: 'option' }, 'ignored'))
      assert.equal('<div>text</div>'.html_safe(true),           div_('text', 'ignored'))
      assert.equal('<div id="id">text</div>'.html_safe(true),   div_('#id', 'text'))
      assert.equal('<div id="id">option</div>'.html_safe(true), div_('#id', 'ignored', { text: 'option' }))
    })

    it('should parse id/classes correctly', () => {
      assert.equal('<div id="id" class="class"></div>'.html_safe(true),           div_('#id.class'))
      assert.equal('<div id="id" class="class"></div>'.html_safe(true),           div_('.class#id'))
      assert.equal('<div id="id" class="class_0 class_1"></div>'.html_safe(true), div_('#id.class_0.class_1'))
      assert.equal('<div id="id" class="class_0 class_1"></div>'.html_safe(true), div_('#id.class_0', { class: 'class_1' }))
      assert.equal('<div id="id" class="class_0 class_2"></div>'.html_safe(true), div_('#id.class_0', { class: { class_1: false, class_2: true } }))
      assert.equal('<div id="option" class="class"></div>'.html_safe(true),       div_('#id.class', { id: 'option' }))
      assert.equal('<div class="class_0 class_1 class_2"></div>'.html_safe(true), div_('.class_0', { class: ['class_1', 'class_2'] }))
      assert.equal('<div class="class_0 class_1 class_2"></div>'.html_safe(true), div_({ class: ['class_0 class_1', 'class_2'] }))
    })

    it('should use :if and :unless options accordingly', () => {
      assert.equal('<div>text</div>'.html_safe(true), div_('text', { if: true }))
      assert.equal('<div>text</div>'.html_safe(true), div_('text', { unless: false }))
      assert.equal(''.html_safe(true),                div_('text', { if: false }))
      assert.equal(''.html_safe(true),                div_('text', { unless: true }))
    })

    it('should flatten :data option', () => {
      assert.equal(
        '<div data-nested-key_0="val_0" data-nested-key_1="val_1"></div>'.html_safe(true),
        div_({ data: { nested: { key_0: 'val_0', key_1: 'val_1' } } })
      )
    })

    it('should escape unsafe text', () => {
      assert.equal(
        '<div>&lt;script&gt;&lt;/script&gt;</div>'.html_safe(true),
        div_('<script></script>')
      )
    })

    it('should allow to turn off text escaping', () => {
      assert.equal('<div><script></script></div>'.html_safe(true), div_('<script></script>', { escape: false }))
      assert.equal('<div><script></script></div>'.html_safe(true), div_('<script></script>'.html_safe(true)))
    })

    it('should allow to return the Element object created', () => {
      assert.true(div$().is_a(HTMLDivElement))
      assert.equal('<div></div>', div$().to_s())
    })

    it('should allow text as Array like #html does', () => {
      assert.equal(`<div>${values.join(' ')}</div>`.html_safe(true),         div_(safe_values))
      assert.equal(`<div>${values.join(' ')}</div>`.html_safe(true),         div_(() => safe_values))
      assert.equal(`<div>${values.join(' ')}</div>`.html_safe(true),         div_({ text: safe_values }))
      assert.equal(`<div id="id">${values.join(' ')}</div>`.html_safe(true), div_('#id', safe_values))
    })

    it('should be able to print defined falsy values', () => {
      const values = [false, 0, NaN, '']
      values.each((value) =>
        assert.equal(`<div>${value}</div>`.html_safe(true), div_(value))
      )
    })

    it('should ignore undefined falsy values', () => {
      const values = [null, undefined]
      values.each((value) =>
        assert.equal('<div></div>'.html_safe(true), div_(value))
      )
    })

    it('should allow to reuse options accross calls', () => {
      const options = { text: 'Some Text' }
      div_(options)
      assert.equal('Some Text', options.text)
    })

    it('should convert to safe text value and add type caster through data-cast', () => {
      assert.equal(
        '<select name="options" value="123" data-cast="to_f" autocomplete="off"></select>',
        select_({ name: 'options', value: 123, 'data-cast': true }).toString()
      )
    })
  })
})
