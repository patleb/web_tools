import '@@vendor/rails-ujs/all'
import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/js/all'
import '@@test/ext_coffee/fixtures/files/js/concepts'

const is_type = (object, type) => {
  return object && object.is_a && object.is_a(type)
}

const js = {
  spy_on: (object, key = null) => {
    if (is_type(object, Object)) {
      object.each((key, value) => {
        if (is_type(value, Function)) {
          jest.spyOn(object, key)
        } else if (is_type(value, Object)) {
          js.spy_on(value)
        }
      })
    } else if (key != null) {
      jest.spyOn(object, key)
    }
  },
}

module.exports = js
