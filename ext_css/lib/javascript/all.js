document.addEventListener('DOMContentLoaded', function() {
  document.documentElement.classList.remove('no-js')
  document.cookie = '_js=yes; path=/' + ((window.location.protocol === 'https:') ? '; secure' : '')
})

if (window.Turbolinks) {
  Rails.document_on('turbolinks:before-render', function () {
    clearTimeout(window.no_transition_timeout)
  })

  Rails.document_on('turbolinks:load', function () {
    window.no_transition_timeout = setTimeout(function () {
      document.documentElement.classList.remove('no-transition')
    }, 250)
  })
}

window.ASCII_SYMBOL = {
  space:            'nbsp',
  hyphen:           '#8209',  // -
  dash:             'ndash',  // –
  copyright:        'copy',   // ©
  registered:       'reg',    // ®
  trademark:        'trade',  // ™
  arrow_left:       'larr',   // ←
  arrow_left_x2:    'laquo',  // «
  arrow_right:      'rarr',   // →
  arrow_right_x2:   'raquo',  // »
  arrow_up:         'uarr',   // ↑
  arrow_up_left:    'lsh',    // ↰
  arrow_up_right:   'rsh',    // ↱
  arrow_down:       'darr',   // ↓
  arrow_down_left:  'ldsh',   // ↲
  arrow_down_right: 'rdsh',   // ↳
  arrow_x:          'harr',   // ↔
  arrow_y:          'varr',   // ↕
  triangle_up:      '#9651',  // △
  triangle_down:    '#9661',  // ▽
  degree:           'deg',    // °
  degree_c:         '#8451',  // ℃
  degree_f:         '#8457',  // ℉
  micro:            'micro',  // µ
  plus_minus:       'plusmn', // ±
  plus:             'plus',   // +
  minus:            'minus',  // −
  multiply:         'times',  // ×
  x:                'times',  // ×
  divide:           'divide', // ÷
  equal:            'equals', // =
  approx:           'asymp',  // ≈
  not_equal:        'ne',     // ≠
  greater:          'gt',     // >
  less:             'lt',     // <
  greater_or_equal: '#8805',  // ≥
  less_or_equal:    '#8804',  // ≤
  squared:          'sup2',   // ²
  cubed:            'sup3',   // ³
  quarter:          'frac14', // ¼
  half:             'frac12', // ½
  three_quarters:   'frac34', // ¾
  bullet:           '#8226',  // •
  ellipsis:         '#8230',  // …
  check:            'check',  // ✓
  cross:            'cross',  // ✗
}

window.ascii_ = function (name) {
  return (ascii(name) + ' ').html_safe(true)
}

window._ascii = function (name) {
  return (' ' + ascii(name)).html_safe(true)
}

window._ascii_ = function (name) {
  return (' ' + ascii(name) + ' ').html_safe(true)
}

window.ascii = function (name) {
  let code = ASCII_SYMBOL[name]
  if (!code) throw `unsupported ascii name '${name}'`
  code = `&${code};`
  return code.html_safe(true)
}
