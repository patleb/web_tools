dom.on_event('rails:attachBindings', { element: document }, (event) => {
  Rails.linkClickSelector += ', a[data-custom-remote-link]'
})
