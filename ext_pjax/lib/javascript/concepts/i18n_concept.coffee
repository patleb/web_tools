class Js.I18nConcept
  global: true

  constants: ->
    TRANSLATIONS: 'ID'

  ready_once: =>
    @locale = $('html').attr('lang') || 'en'
    @translations = $(@TRANSLATIONS).data('translations') || {}
    moment.locale(@locale)

  t: (key) =>
    @translations[key] || key.humanize()
