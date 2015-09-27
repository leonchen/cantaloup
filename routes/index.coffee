Storage = require '../lib/storage'

module.exports = (app) ->
  storage = new Storage()

  getParams = (req) ->
    params = {}
    return params

  getKV = (req, res, next) ->
    params = getParams(req)
    storage.get req.path, params, (err, data) ->
      return res.status(500).send(err) if err
      return res.status(200).send data
    

  createKV = (req, res, next) ->
    params = getParams(req)
    if req.query.link == "true"
      return res.status(403).send("source query required") unless req.query.source
      params.link = true
      params.source = req.query.source
    else
      params.data = req.query.data || req.body.data

    storage.create req.path, params, (err, data) ->
      return res.status(500).send(err) if err
      return res.status(200).send data

  updateKV = (req, res, next) ->
    params = getParams(req)
    if req.query.link == "true"
      return res.status(403).send("source query required") unless req.query.source
      params.link = true
      params.source = req.query.source
    else
      params.data = req.query.data || req.body.data

    storage.update req.path, params, (err, data) ->
      return res.status(500).send(err) if err
      return res.status(200).send(data)

  checkKV = (req, res, next) ->
    storage.head req.path, (exists) ->
      if exists
        res.status(200).send "key set"
      else
        res.status(404).send "key not set"

  removeKV = (req, res, next) ->
    storage.delete req.path, (res) ->
      res.status(200).send ""


  handleKV = (req, res, next) ->
    method = (req.params.method || req.method).toLowerCase()
    switch method
      when "get" then getKV(req, res, next)
      when "post" then createKV(req, res, next)
      when "put" then updateKV(req, res, next)
      when "head" then checkKV(req, res, next)
      when "delete" then removeKV(req, res, next)
      else
        res.status(404)

  app.get "/", (req, res, next) ->
    res.status(200).send ""

  app.use "/api/kv", (req, res, next) ->
    req.params.method = req.query.method if req.query.method
    handleKV(req, res, next)


  app.use "/kv", (req, res, next) ->
    handleKV(req, res, next)

