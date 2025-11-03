class window.Cookie
  @set: (key, value = '') ->
    Cookies.set(key, value, secure: (window.location.protocol is 'https:'))

  @set_json: (root, key, value) =>
    json = @get_json(root)
    json[key] = value
    @set(root, json)

  @get: (key) ->
    Cookies.get(key)

  @get_json: (key) =>
    json = Cookies.getJSON(key)
    if json?.is_a(Object) then json else {}

  @remove: (key) ->
    Cookies.remove(key)

  @remove_json: (root, keys...) =>
    json = @get_json(root)
    keys.each (key) -> json.delete(key)
    @set(root, json)
