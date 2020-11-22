import './mixins/current'

const mixins = {
  methods: {
    $assign: function (name, value) {
      if (!_.isEqual(this[name], value)) {
        this[name] = value
      }
      return value
    },
    $store_get: function (scope, name) {
      return this.$store.state[scope][name]
    },
    $store_set: function (scope, name, value) {
      this.$store.commit(`set_${scope}_${name}`, value)
    },
    $is_desktop: function () {
      return !this.$is_mobile()
    },
    $is_mobile: function () {
      let { width, height } = this.$current_size
      return (width < 768) || (height < 400)
    },
    $client_size: function () {
      let width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth
      let height = window.innerHeight || document.documentElement.clientHeight|| document.body.clientHeight
      return { width, height }
    },
    $transform_ordered_values: function (ordered_hash, selections, mapping = (value) => value) {
      let selected_keys = _.isArray(selections) ? selections : _.keys(selections)
      return _.transform(ordered_hash, (result, value, key) => {
        if (_.includes(selected_keys, key)) {
          result[key] = mapping(value, key)
        }
      }, {})
    },
    // https://github.com/ankane/chartkick/blob/master/vendor/assets/javascripts/chartkick.js#L388
    $add_opacity: function(hex, opacity) {
      let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
      return result ? "rgba(" + parseInt(result[1], 16) + ", " + parseInt(result[2], 16) + ", " + parseInt(result[3], 16) + ", " + opacity + ")" : hex
    },
    $to_date: function (value) {
      if (value) {
        if (_.isPlainObject(value) && _.has(value, 'year')) {
          return value
        }
        let [year, month, day] = value.toString().split('-').map(v => +(v))
        return { year, month, day }
      }
    },
    $to_string: function (value) {
      if (value != null) {
        return value.toString()
      }
    },
    $true: function (value) {
      return !this.$false(value)
    },
    $false: function (value) {
      return value == null || value === false
    },
    $sleep: function (ms) {
      return new Promise(resolve => setTimeout(resolve, ms))
    },
    $url_params: function (query) {
      if (!query) {
        return {}
      }
      let pairs = (/^[?#]/.test(query) ? query.slice(1) : query).split('&')
      return _.transform(pairs, (params, pair) => {
        let [key, value] = pair.split('=')
        params[key] = value ? decodeURIComponent(value.replace(/\+/g, ' ')) : ''
      }, {})
    },
  }
}

Vue.mixin(mixins)

export default {
  errorCaptured (error, vm, info) {
    if (process.env.NODE_ENV === 'production') {
      $rescue(this.$http, {
        message: `${info}: ${error}`,
        backtrace: error.stack || [],
        data: {
          tag: vm.$el.localName, id: vm.$el.id, class: vm.$el.className,
          ...this.$current_size
        }
      })
      return false
    }
  },
  created: function () {
    this.app_params = this.$url_params(window.location.search)
    window.addEventListener('popstate', this.on_popstate)
  },
  mounted: function () {
    this.app_size = this.$client_size()
    window.addEventListener('resize', this.on_resize)
  },
  beforeDestroy: function () {
    window.removeEventListener('resize', this.on_resize)
    window.removeEventListener('popstate', this.on_popstate)
  },
  methods: {
    on_resize: _.throttle(function () {
      this.app_size = this.$client_size()
    }, 300),
    on_popstate: function () {
      this.app_params = this.$url_params(window.location.search)
    },
  }
}
