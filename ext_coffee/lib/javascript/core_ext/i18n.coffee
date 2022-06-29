class window.I18n
  @locale: 'en'
  @translations: {}

  @t: (key, options = {}) ->
    escape = options.delete('escape') ? true
    locale = options.delete('locale') ? @locale
    if (string = @translations[locale]?.dig(key))?
      for name, value of options
        string = string.replace("%{#{name}}", value)
      string = string.html_safe?(true) unless escape
    string ? key.gsub('.', ' ').humanize()

  @with_locale: (locale, callback) ->
    locale_was = @locale
    @locale = locale
    callback()
    @locale = locale_was
    return

  @on_load: ->
    I18n.locale = document.documentElement.getAttribute('lang') or I18n.locale
    Rails.$('.js_i18n').each (element) ->
      if translations = element.getAttribute('data-translations')
        if translations = JSON.safe_parse(translations)
          I18n.translations.deep_merge(translations)

  @on_ready: (event) ->
    return if event.data.info.once
    I18n.on_load()

Rails.document_on 'DOMContentLoaded', I18n.on_load
Rails.document_on 'turbolinks:load', I18n.on_ready