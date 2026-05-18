class Js.UserConcept extends Js.Base
  global: true

  @readers
    role: -> Cookie.get('_role') ? 'null'
    logged_in: -> @role isnt 'null'
