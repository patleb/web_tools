class Turbolinks.SnapshotCache
  constructor: (@size) ->
    @keys = []
    @snapshots = {}

  has: (location) ->
    key = key_for(location)
    key of @snapshots

  get: (location) ->
    return unless @has(location)
    snapshot = @read(location)
    @touch(location)
    snapshot

  put: (location, snapshot) ->
    @write(location, snapshot)
    @touch(location)
    snapshot

  # Private

  read: (location) ->
    key = key_for(location)
    @snapshots[key]

  write: (location, snapshot) ->
    key = key_for(location)
    @snapshots[key] = snapshot

  touch: (location) ->
    key = key_for(location)
    index = @keys.indexOf(key)
    @keys.splice(index, 1) if index > -1
    @keys.unshift(key)
    @trim()

  trim: ->
    for key in @keys.splice(@size)
      delete @snapshots[key]

  key_for = (location) ->
    Turbolinks.Location.wrap(location).to_cache_key()
