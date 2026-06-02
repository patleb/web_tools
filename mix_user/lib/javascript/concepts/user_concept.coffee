class Js.UserConcept extends Js.Base
  global: true

  @readers
    role: -> Cookie.get('_role') ? 'null'
    logged_in: -> @role isnt 'null'

  ready: ->
    if Cookie.get('_user_denied')?.to_b()
      Cookie.remove('_user_denied')
      Flash.notice I18n.t('flash.denied')
