class window.I18n
  @translations: {}

  @t: (key, options = {}) ->
    escape = options.delete('escape') ? true
    locale = options.delete('locale') ? @locale
    if (string = @translations[locale]?.dig(key))?
      for name, value of options
        string = string.replace("%{#{name}}", value)
      string = string.html_safe?(true) unless escape
    string ? key.gsub('.', ' ').humanize()

  @with_locale: (@locale, callback) ->
    callback()
    @locale = @default_locale
    return

  @on_load: ->
    I18n.default_locale = document.documentElement.getAttribute('lang') or 'en'
    I18n.locale = I18n.default_locale
    Rails.$('.js_i18n').each (element) ->
      if translations = element.getAttribute('data-translations')
        if translations = JSON.safe_parse(translations)
          I18n.translations = I18n.translations.deep_merge(translations)

Rails.document_on 'turbolinks:load', I18n.on_load
