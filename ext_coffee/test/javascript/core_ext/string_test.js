import './spec_helper'

describe('String', () => {
  test('#eql', () => {
    assert.true("abc".eql("abc"))
    assert.false("abc".eql("cba"))
  })

  test('#is_a', () => {
    assert.true(''.is_a(String))
    assert.false(''.is_a(Object))
  })

  test('#to_b', () => {
    assert.equal(Array(7).fill(true), ['true', 't', 'yes', 'y', '1', '1.0', '✓'].map((v) => v.to_b()))
    assert.equal(Array(8).fill(false), ['false', 'f', 'no', 'n', '0', '0.0', '✘', ' '].map((v) => v.to_b()))
    assert.raise(Error, 'invalid'.to_b)
  })

  test('#to_i', () => {
    assert.equal(NaN, ''.to_i())
    assert.equal(0, '00'.to_i())
    assert.equal(1, '01'.to_i())
    assert.equal(1, '1.0'.to_i())
    assert.equal(0xf, '0xf'.to_i())
    assert.equal(0xf, 'f'.to_i(16))
  })

  test('#to_a', () => {
    assert.equal([1, 2], '[1, 2]'.to_a())
    assert.equal([{ a: 1 }], '[{ "a": 1 }]'.to_a())
  })

  test('#to_h', () => {
    assert.equal({ a: 1 }, '{ "a": 1 }'.to_h())
    assert.raise(/invalid/, '{ a: 1 }'.to_h)
  })

  test('#to_date', () => {
    assert.nan(''.to_date())
    assert.equal(Date.current(), 'now'.to_date())
    assert.equal(new Date(Date.UTC(2001, 0, 1, 1, 1, 1)), '2001-01-01T01:01:01Z'.to_date())
    assert.equal(new Date(Date.UTC(2001, 0, 1, 1, 1, 1, 1.001001)), '2001-01-01 01:01:01.001001001 UTC'.to_date())
  })

  test('#to_html', () => {
    let element = document.createElement('div')
    element.innerHTML = 'Hello'
    assert.equal(element, '<div>Hello</div>'.to_html()[0])
  })

  test('#html_blank', () => {
    assert.true('<p>&nbsp;</p><br>'.html_blank())
    assert.false('text'.html_blank())
  })

  test('#blank', () => {
    assert.true(' \n'.blank())
    assert.false('&nbsp;'.blank())
  })

  test('#presence', () => {
    assert.nil(' \n'.presence())
    assert.equal('text', 'text'.presence())
  })

  test('#empty', () => {
    assert.true(''.empty())
    assert.false(' '.empty())
  })

  test('#chars', () => {
    assert.equal(['a', 'b', 'c'], 'abc'.chars())
  })

  test('#index', () => {
    assert.equal(1, 'abc'.index('b'))
    assert.nil('abc'.index('f'))
    assert.equal(2, 'abc'.index(/c$/))
    assert.nil('abc'.index(/^b/))
  })

  test('#include', () => {
    assert.true('abc'.include('bc'))
    assert.false('abc'.include('ac'))
  })

  test('#safe_text', () => {
    const string = '<script>`${alert("&nbsp;")}`</script>'
    assert.equal('&lt;script&gt;&#x60;${alert(&quot;&amp;nbsp;&quot;)}&#x60;&lt;/script&gt;', string.safe_text())
  })

  test('#safe_regex', () => {
    const string = '[example](https://example.com/)'
    assert.equal('\\[example\\]\\(https://example\\.com/\\)', string.safe_regex())
  })

  test('#gsub', () => {
    assert.equal('fbf', 'abc'.gsub(/(^a|c$)/, 'f'))
    assert.equal('fbf', 'aba'.gsub('a', 'f'))
  })

  test('#ljust', () => {
    assert.equal('a--', 'a'.ljust(3, '-'))
  })

  test('#rjust', () => {
    assert.equal('--a', 'a'.rjust(3, '-'))
  })

  test('#camelize', () => {
    assert.equal('::RootPath::To::ClassName.ext::', '/root_path/to/class-name.ext /'.camelize())
  })

  test('#underscore', () => {
    assert.equal('/root_path/to/class_name.ext/', '::RootPath::To::ClassName.ext::'.underscore())
  })

  test('#full_underscore', () => {
    assert.equal('root_path_to_class_name_ext', '::RootPath::To::ClassName.ext::'.full_underscore())
  })

  test('#parameterize', () => {
    assert.equal('root_path-to-class-name-ext', '/root_path/to/Class-Name.Ext /'.parameterize())
  })

  test('#humanize', () => {
    assert.equal('Root path to class-name.ext', 'root_path_to_class-name.ext'.humanize())
  })

  test('#pluralize, #singularize', () => {
    assert.equal('days', 'day'.pluralize())
    assert.equal('day', 'days'.singularize())
    assert.equal('categories', 'category'.pluralize())
    assert.equal('category', 'categories'.singularize())
    assert.equal('ashes', 'ash'.pluralize())
    assert.equal('ash', 'ashes'.singularize())
    assert.equal('axes', 'axis'.pluralize())
    assert.equal('axis', 'axes'.singularize())
    assert.equal('analyses', 'analysis'.pluralize())
    assert.equal('analysis', 'analyses'.singularize())
  })

  test('#acronym', () => {
    assert.equal('RPTCN', '::RootPath::To::ClassName.ext::'.acronym())
  })

  test('#constantize', () => {
    assert.equal(Test.SimpleConcept, 'Test.SimpleConcept'.constantize())
    assert.equal(Test.SimpleConcept.prototype.Element, 'Test.SimpleConcept::Element'.constantize())
    assert.nil('Unknown'.constantize())
    assert.raise(Error, '<invalid>'.constantize)
  })

  test('#partition', () => {
    assert.equal(['', '#', 'id.class'], '#id.class'.partition('#'))
    assert.equal(['', '#id', '.class'], '#id.class'.partition(/#id/))
    assert.equal(['#id.class', '', ''], '#id.class'.partition('+'))
  })

  test('#start_with', () => {
    assert.true('abc'.start_with('a', 'b'))
    assert.false('abc'.start_with('c'))
  })

  test('#end_with', () => {
    assert.true('abc'.end_with('b', 'c'))
    assert.false('abc'.end_with('a'))
  })
})
