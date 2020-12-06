html_([
  head_([
    meta_('http-equiv': 'Content-Type', content: 'text/html; charset=utf-8'),
    style_{ area(:style) } # Email styles need to be inline
  ]),
  body_([
    yield
  ])
])
