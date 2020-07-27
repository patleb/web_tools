<template>
  <a role="button" v-if="type === 'button'" @click="set_locale(next_locale)">
    {{ pretty_locale(next_locale) }}
  </a>
  <dropdown v-else-if="type === 'dropdown'">
    <btn size="sm" class="dropdown-toggle">
      {{ $i18n.locale }} <i class="fa fa-angle-down"/>
    </btn>
    <template slot="dropdown">
      <li v-for="locale in available_locales" :class="{ active: locale === $i18n.locale }">
        <a role="button" @click="set_locale(locale)">
          {{ pretty_locale(locale) }}
        </a>
      </li>
    </template>
  </dropdown>
  <ul v-else>
    <li v-for="locale in available_locales" :class="{ active: locale === $i18n.locale }">
      <a role="button" @click="set_locale(locale)">
        {{ pretty_locale(locale) }}
      </a>
    </li>
  </ul>
</template>

<script>
  export default {
    props: [
      'type',
    ],
    created: function () {
      this.$i18n.locale = this.$current_params.locale || this.$localStorage.get('locale', this.navigator_locale())
    },
    methods: {
      set_locale: function (locale) {
        this.$i18n.locale = locale
        this.$localStorage.set('locale', locale)
      },
      pretty_locale: function (locale) {
        return this.$i18n.messages[locale].locale.lang
      },
      navigator_locale: function () {
        let locale = navigator.language.substring(0, 2)
        return _.includes(this.available_locales, locale) ? locale : this.available_locales[0]
      }
    },
    computed: {
      next_locale: function () {
        return _.find(this.available_locales, l => l !== this.$i18n.locale)
      },
      available_locales: function () {
        return _.keys(this.$i18n.messages).sort()
      },
    }
  }
</script>
