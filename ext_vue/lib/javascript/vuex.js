const store_accessors = (scope, ...names) => {
  return _.transform(window.$store_defaults[scope], (result, _value, name) => {
    if (names.length === 0 || names.length && names.includes(name)) {
      result[name] = {
        get () {
          let value = this.$store.state[scope][name]
          return (value != null) ? value : window.$store_defaults[scope][name]
        },
        set (value) {
          this.$store.commit(`set_${scope}_${name}`, value)
        }
      }
    }
  }, {})
}

window.$store_accessors = store_accessors

export const initialize_store_modules = (defaults) => {
  window.$store_defaults = defaults

  return _.transform(window.$store_defaults, (modules, _value, scope) => {
    modules[scope] = {
      state: {
        ...window.$store_defaults[scope]
      },
      mutations: {
        ..._.transform(window.$store_defaults[scope], (result, _value, name) => {
          result[`set_${scope}_${name}`] = (state, value) => {
            return state[name] = value
          }
        }, {})
      }
    }
  }, {})
}
