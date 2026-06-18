class Js.UserConcept extends Js.Base
  global: true

  @readers
    role: -> Cookie.get('_role') ? 'null'
    logged_in: -> @role isnt 'null'

  ready: ->
    if i18n_key = Cookie.get('_user_denied')
      Cookie.remove('_user_denied')
      Flash.alert I18n.t(i18n_key, scope: 'flash', default: 'denied').html_safe(true)
