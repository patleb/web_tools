<template>
  <dropdown>
    <btn size="sm" class="dropdown-toggle">
      {{ $i18n.locale }} <i class="fa fa-angle-down"/>
    </btn>
    <template slot="dropdown">
      <li v-for="locale in ['en', 'fr']" :class="{ active: locale === $i18n.locale }">
        <a role="button" @click="set_locale(locale)">
          {{ pretty_locale(locale) }}
        </a>
      </li>
    </template>
  </dropdown>
</template>

<script>
  export default {
    created: function () {
      this.$i18n.locale = this.$current_params.locale || this.$localStorage.get('locale', navigator.language.substring(0, 2))
    },
    methods: {
      set_locale: function (locale) {
        this.$i18n.locale = locale
        this.$localStorage.set('locale', locale)
      },
      pretty_locale: function (locale) {
        return this.$i18n.messages[locale]['lang']
      }
    }
  }
</script>
