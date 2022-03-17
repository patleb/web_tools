class Js.TimeZoneConcept
  global: true

  ready_once: =>
    old_Intl = window.Intl
    @name =
      try
        window.Intl = undefined
        tz = jstz.determine().name()
        window.Intl = old_Intl
        tz
      catch e
        # sometimes (on android) you can't override intl
        jstz.determine().name()

    Js.Cookie.set('time_zone', @name)
