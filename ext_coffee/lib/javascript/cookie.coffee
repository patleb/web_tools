class Js.Cookie
  @set: (key, value = '') ->
    Cookies.set("js.#{key}", value, secure: (window.location.protocol == 'https:'))

  @set_json: (root, key, value) =>
    json = @get_json(root)
    json[key] = value
    @set(root, json)

  @get: (key) ->
    Cookies.get("js.#{key}")

  @get_json: (key) =>
    json = Cookies.getJSON("js.#{key}")
    if json?.is_a(Object) then json else {}

  @remove: (key) ->
    Cookies.remove("js.#{key}")

  @remove_json: (root, keys...) =>
    json = @get_json(root)
    keys.each (key) -> json.delete(key)
    @set(root, json)
