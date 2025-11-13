class window.I18n
  @locale: 'en'
  @fallback: 'en'
  @translations: {}

  @t: (key, options = {}) =>
    scope = options.delete('scope')
    escape = options.delete('escape') ? true
    locale = options.delete('locale') ? @locale
    fallback = options.delete('fallback') ? @fallback
    key = "#{scope}.#{key}" if scope
    result = @translations[locale]?.dig(key)
    result ?= @translations[fallback]?.dig(key) unless locale is fallback
    if result?.is_a String
      for name, value of options
        result = result.replace("%{#{name}}", value)
      result = result.html_safe?(true) unless escape
    result ? key.gsub('.', ' ').humanize()

  @with_locale: (locale, callback) =>
    locale_was = @locale
    @locale = locale
    try
      callback()
    finally
      @locale = locale_was
    return

  @on_load: ->
    I18n.locale = document.documentElement.getAttribute('lang') or I18n.locale
    Rails.$('.js_i18n').each (element) ->
      if translations = element.getAttribute('data-value')
        if translations = JSON.safe_parse(translations)
          I18n.translations.deep_merge(translations)
          element.remove()

  @on_ready: (event) ->
    return if event.data.info.once
    I18n.on_load()

Rails.document_on 'DOMContentLoaded', I18n.on_load
Rails.document_on 'turbolinks:load', I18n.on_ready
window.t = I18n.t
