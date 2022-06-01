dom.on_event({ element: document, 'rails:attachBindings': (event) => {
  Rails.click_links += ', a[data-custom-remote-link]'
}})
