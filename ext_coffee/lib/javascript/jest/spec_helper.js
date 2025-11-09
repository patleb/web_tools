require('@@lib/ext_coffee/jest/all')
require('@@lib/ext_coffee/jest/concepts')

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
