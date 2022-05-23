dom.on_event('rails:attachBindings', { element: document }, (event) => {
  Rails.linkClickSelector += ', a[data-custom-remote-link]'
  assert.not_null(Rails.href)
})
