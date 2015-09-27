redis = require 'redis'
async = require 'async'

VALUES_KEY = 'CANTALOUP:VALS'
LINKS_KEY = "CANTALOUP:LINKS"

class Storage
  constructor: (options) ->
    @client = redis.createClient()
    @ready = false

    @data =
      vals: {}
      links: {}
    @loadData()

  loadData: ->
    @client.hgetall VALUES_KEY, (err, data) =>
      @loadValues(data)
      @client.hgetall LINKS_KEY, (err, data) =>
        @loadLinks(data)
        @ready = true

  loadValues: (data) ->
    return unless data
    l = data.length
    i = 0
    while i < l-2
      @data.vals[data[i]] = JSON.parse(data[i+1])
      i+=2

  loadLinks: (data) ->
    return unless data
    l = data.length
    i = 0
    while i < l-2
      @data.links[data[i]] = data[i+1]
      i+=2

    for l, s of @data.links
      @linkValue(l, s)

  linkValue: (path, source) ->
    pks = @getKeys(path)
    lastPK = pks.pop()
    d = @data.vals
    for pk in pks
      d[pk] = {} unless d[pk]
      d = d[pk]

    sks = @getKeys(source)
    lastSK = sks.pop()
    v = @data.vals
    for sk in sks
      v[sk] = {} unless v[sk]
      v = v[sk]

    d[lastPK] = v[lastSK]


  get: (path, params, cb) ->
    ps = @getKeys(path)
    v = @data.vals
    for p in ps
      return cb "no such key" unless v[p]
      v = v[p]
    return cb(null, v)


  create: (path, params, cb) ->
    return cb("key already exists") if @valueExists(path)
    if params.link
      @setLink(path, params.source, cb)
    else
      @set(path, params.data, cb)


  setLink: (path, source, cb) ->
    console.log path, source
    @linkValue(path, source)
    try
      JSON.stringify(@getValue(path))
    catch e
      return cb "recursive data set"
    @client.hset(LINKS_KEY, path, source, cb)


  getValue: (path) ->
    ks = @getKeys(path)
    d = @data.vals
    for k in ks
      d[k] = {} unless d[k]
      d = d[k]
    return d


  set: (path, data, cb) ->
    k = @getKeys(path)[0]
    return cb("key required") unless k
    d = @getValue(path)
    d.value = data
    @client.hset(VALUES_KEY, k, @data.vals[k], cb)


  getKeys: (path) ->
    return path.split("/").filter((p) -> return p)

  valueExists: (path) ->
    d = @getValue(path)
    return Object.keys(d).length > 0


  update: (path, params, cb) ->
    if params.link
      @setLink(path, params.source, cb)
    else
      @set(path, params.data, cb)


  delete: (path, cb) ->
    ks = @getKeys(path)
    key = ks.pop()
    d = @data.vals
    for k in ks
      d[k] = {} unless d[k]
      d = d[k]
    delete d[key]
    @set(path, d, cb)


  head: (path, cb) ->
    cb(@valueExists(path))


module.exports = Storage
