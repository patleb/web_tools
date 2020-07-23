String.define_methods
  html_safe: (safe = null) ->
    if safe?
      value = new String(this)
      value._html_safe = !!safe
      value
    else
      !!this._html_safe
