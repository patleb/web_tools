import concepts from './spec_helper'

describe('Js.TagConcept', () => {
  const values = ['Prev', 'Next'].map(text => `<div>${text}</div>`)
  const safe_values = values.map(v => v.html_safe(true))

  beforeAll(async () => {
    concepts.load_document()
    await tick()
  })

  it('should define tags', () => {
    Tag.define('blockquote')
    assert.equal('<blockquote data-href="#">HOME</blockquote>', blockquote_({ 'data-href': '#' }, () => 'HOME').to_s())
  })

  describe('#h_', () => {
    it('should join nodes and respect #html_safe value', () => {
      let expected = [[safe_values.first()], safe_values]
      expected.each((expect) => {
        let actual = h_(...expect)
        assert.equal(expect.join(' '), actual.to_s())
        assert.true(actual.html_safe())
      })
      expected = [[values.first()], values]
      expected.each((expect) => {
        let actual = h_(...expect)
        assert.equal(expect.join(' ').safe_text(), actual.to_s())
        assert.true(actual.html_safe())
      })
      assert.html_equal('<div>Hello</div><div>World!</div>', h_(div$('Hello'), div_('World!'), null))
    })

    it('should allow to pass function as argument', () => {
      assert.equal('HOME', h_(() => 'HOME').to_s())
      assert.equal('HOME', h_(() => ['HOME']).to_s())
    })
  })

  describe('#if_', () => {
    it('should print if condition is true', () => {
      assert.equal(safe_values.first(), if_(true, safe_values.first()))
      assert.equal('', if_(false, values.first()))
    })
  })

  describe('#unless_', () => {
    it('should print unless condition is true', () => {
      assert.equal(safe_values.first(), unless_(false, safe_values.first()))
      assert.equal('', unless_(true, safe_values.first()))
    })
  })

  describe('#with_tag', () => {
    it('should prefer text option, then first arg, then last arg', () => {
      assert.equal('<div>option</div>', div_('text', { text: 'option' }, 'ignored').to_s())
      assert.equal('<div>text</div>', div_('text', 'ignored').to_s())
      assert.equal('<div id="id">text</div>', div_('#id', 'text').to_s())
      assert.equal('<div id="id">option</div>', div_('#id', 'ignored', { text: 'option' }).to_s())
    })

    it('should parse id/classes correctly', () => {
      assert.equal('<div id="id" class="class"></div>', div_('#id.class').to_s())
      assert.equal('<div id="id" class="class"></div>', div_('.class#id').to_s())
      assert.equal('<div id="id" class="class_0 class_1"></div>', div_('#id.class_0.class_1').to_s())
      assert.equal('<div id="id" class="class_0 class_1"></div>', div_('#id.class_0', { class: 'class_1' }).to_s())
      assert.equal('<div id="id" class="class_0 class_2"></div>', div_('#id.class_0', { class: { class_1: false, class_2: true } }).to_s())
      assert.equal('<div id="option" class="class"></div>', div_('#id.class', { id: 'option' }).to_s())
      assert.equal('<div class="class_0 class_1 class_2"></div>', div_('.class_0', { class: ['class_1', 'class_2'] }).to_s())
      assert.equal('<div class="class_0 class_1 class_2"></div>', div_({ class: ['class_0 class_1', 'class_2'] }).to_s())
    })

    it('should use :if and :unless options accordingly', () => {
      assert.equal('<div>text</div>', div_('text', { if: true }).to_s())
      assert.equal('<div>text</div>', div_('text', { unless: false }).to_s())
      assert.equal('', div_('text', { if: false }).to_s())
      assert.equal('', div_('text', { unless: true }).to_s())
    })

    it('should flatten :data option', () => {
      assert.equal(
        '<div data-nested-key_0="val_0" data-nested-key_1="val_1"></div>',
        div_({ data: { nested: { key_0: 'val_0', key_1: 'val_1' } } }).to_s()
      )
    })

    it('should escape unsafe text', () => {
      assert.equal('<div>&amp;lt;script&amp;gt;&amp;lt;/script&amp;gt;</div>', div_('<script></script>').to_s())
    })

    it('should allow to turn off text escaping', () => {
      assert.equal('<div><script></script></div>', div_('<script></script>', { escape: false }).to_s())
      assert.equal('<div><script></script></div>', div_('<script></script>'.html_safe(true)).to_s())
    })

    it('should allow to return the Element object created', () => {
      assert.true(div$().is_a(HTMLDivElement))
      assert.equal('<div></div>', div$().to_s())
    })

    it('should allow text as Array like #html does', () => {
      assert.equal(`<div>${values.join(' ')}</div>`, div_(safe_values).to_s())
      assert.equal(`<div>${values.join(' ')}</div>`, div_(() => safe_values).to_s())
      assert.equal(`<div>${values.join(' ')}</div>`, div_({ text: safe_values }).to_s())
      assert.equal(`<div id="id">${values.join(' ')}</div>`, div_('#id', safe_values).to_s())
    })

    it('should be able to print defined falsy values', () => {
      const values = [false, 0, NaN, '']
      values.each((value) =>
        assert.equal(`<div>${value}</div>`, div_(value).to_s())
      )
    })

    it('should ignore undefined falsy values', () => {
      const values = [null, undefined]
      values.each((value) =>
        assert.equal('<div></div>', div_(value).to_s())
      )
    })

    it('should allow to reuse options accross calls', () => {
      const options = { text: 'Some Text' }
      div_(options)
      assert.equal('Some Text', options.text)
    })
  })
})
