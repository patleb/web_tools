const mixins = {
  computed: {
    $current_size: function () {
      return this.$store.state.app.app_size
    },
    $current_params: function () {
      return this.$store.state.app.app_params
    },
    $current_locales: function () {
      return this.$i18n.messages[this.$i18n.locale]
    },
  }
}

Vue.mixin(mixins)
