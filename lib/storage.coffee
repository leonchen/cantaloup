{EventEmitter} = require 'events'
redis = require 'redis'
async = require 'async'

VALUES_KEY = 'CANTALOUP:VALS'
LINKS_KEY = "CANTALOUP:LINKS"

class Storage extends EventEmitter
  constructor: (options) ->
    @redisValuesKey = options.valuesKey || VALUES_KEY
    @redisLinksKey = options.linksKey || LINKS_KEY
    {host, port} = options.redis || {}
    @client = redis.createClient(port, host)
    @ready = false

    @data =
      vals: {}
      links: {}
    @loadData()

  reset: (cb) ->
    @data =
      vals: {}
      links: {}
    @client.del [@redisValuesKey, @redisLinksKey], ->
      console.log "0000000"
      cb()

  loadData: ->
    @client.hgetall @redisValuesKey, (err, data) =>
      @loadValues(data)
      @client.hgetall @redisLinksKey, (err, data) =>
        @loadLinks(data)
        @ready = true
        @emit "ready"

  loadValues: (data) ->
    return unless data
    for k, j of data
      @data.vals[k] = JSON.parse(j)

  loadLinks: (data) ->
    return unless data
    for k, j of data
      @data.links[k] = j
    for l, s of @data.links
      @linkKey(l, s)

  linkKey: (path, source) ->
    pks = @getKeys(path)
    return cb("path cannot be empty") if pks.length < 1
    sks = @getKeys(source)
    return cb("source cannot be empty") if sks.length < 1
    lastPK = pks.pop()
    lastSK = sks.pop()

    d = @data.vals
    for pk in pks
      d[pk] = {} unless d[pk]
      d = d[pk]

    v = @data.vals
    for sk in sks
      v[sk] = {} unless v[sk]
      v = v[sk]

    d[lastPK] = v[lastSK]
    @data.links[path] = source


  get: (path, params, cb) ->
    if arguments.length == 2 and typeof arguments[1] == "function"
      cb = params
      params = {}

    ps = @getKeys(path)
    v = @data.vals
    for p in ps
      return cb "no such key" unless v[p]
      v = v[p]
    cb(null, v)


  create: (path, params, cb) ->
    return cb("path invalid") unless @pathValid(path)
    return cb("key already exists") if @valueExists(path)
    if params.link
      @setLink(path, params.source, cb)
    else
      @set(path, params.data, cb)


  setLink: (path, source, cb) ->
    origin = @data.links[path]
    @linkKey(path, source)
    try
      JSON.stringify(@getValue(path))
    catch e
      @linkKey(path, origin) if origin
      return cb "cannot set circular values"
    @client.hset(@redisLinksKey, path, source, cb)


  getValue: (path) ->
    ks = @getKeys(path)
    d = @data.vals
    for k in ks
      d[k] = {} unless d[k]
      d = d[k]
    return d


  set: (path, data, cb) ->
    ks = @getKeys(path)
    return cb("path cannot be empty") if ks.length < 1
    k = ks[0]
    return cb("key required") unless k
    d = @getValue(path)
    d.value = data
    d.type = "value"
    @client.hset(@redisValuesKey, k, JSON.stringify(@data.vals[k]), cb)


  getKeys: (path) ->
    return path.split("/").filter((p) -> return p)


  pathValid: (path) ->
    ks = @getKeys(path)
    return false if ks.length < 1
    d = @data.vals
    for k in ks
      return true unless d[k]
      return false if d[k] and d[k].type == "value"
      d = d[k]
    return true


  valueExists: (path) ->
    d = @getValue(path)
    return Object.keys(d).length > 0


  update: (path, params, cb) ->
    if params.link
      return cb("can't update linking on a non-link key") unless @data.links[path]
      @setLink(path, params.source, cb)
    else
      return cb("can't update value on a link key") if @data.links[path]
      @set(path, params.data, cb)


  delete: (path, cb) ->
    ks = @getKeys(path)
    l = ks.length
    return cb("path cannot be empty") if l < 1
    root = ks[0]
    key = ks.pop()
    d = @data.vals
    for k in ks
      d[k] = {} unless d[k]
      d = d[k]
    delete d[key]

    if @data.links[path]
      delete @data.links[path]
      @client.hdel @redisLinksKey, path, cb
    else
      if l == 1
        @client.hdel @redisValuesKey, root, cb
      else
        @client.hset(@redisValuesKey, root, JSON.stringify(@data.vals[root]), cb)


  head: (path, cb) ->
    cb(@valueExists(path))


module.exports = Storage
