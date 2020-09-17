class Js.I18nConcept
  global: true

  constants: ->
    TRANSLATIONS: 'ID'

  ready_once: =>
    @locale = $('html').attr('lang') || 'en'
    @translations = $(@TRANSLATIONS).data('translations') || {}
    moment.locale(@locale)
    Js.Cookie.set('locale', @locale)

  t: (key, escape = true) =>
    (if escape then @translations[key] else @translations[key]?.html_safe(true)) || key.humanize()
