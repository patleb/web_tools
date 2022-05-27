let window_location_was = window.location
let form_submit_was = HTMLFormElement.prototype.submit

const url = {
  mock_location: (url = 'https://localhost') => {
    const location = new URL(url)
    location.assign = jest.fn()
    location.reload = jest.fn()
    location.replace = jest.fn()
    window_location_was = window.location
    delete window.location
    window.location = location
  },
  delete_location: () => {
    delete window.location
  },
  reset_location: () => {
    window.location = window_location_was
  },
  stub_submit: () => {
    delete HTMLFormElement.prototype.submit
    HTMLFormElement.prototype.submit = function() {
      this.dispatchEvent(new CustomEvent('submit', { bubbles: true, cancelable: true }))
    }
  },
  reset_submit: () => {
    HTMLFormElement.prototype.submit = form_submit_was
  },
  get_anchor: (url) => {
    let match = url.match(/#(.+)$/)
    if (match) {
      return match[1]
    }
  },
}
global.url = url
