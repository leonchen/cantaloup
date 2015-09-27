should = require 'should'
Storage = require '../lib/storage'

describe "storage", ->
  storage = null
  before (done) ->
    params =
      valuesKey: "cantaloup:test:values"
      linksKey: "cantaloup:test:links"
    storage = new Storage(params)
    storage.on "ready", ->
      storage.reset done

  it "should create key/value", ->
    storage.create "/this/is/a/key", {data: "key value"}, (err) ->
      should(err).not.be.ok
      storage.get "this/is/a/", (err, val) ->
        should(err).not.be.ok
        should(val.key.value).equal("key value")

  it "should get recursive values", ->
    storage.get "this/", (err, val) ->
      should(err).not.be.ok
      should(val.is.a.key.value).equal("key value")

  it "should create a link key", ->
    storage.create "/this/is/another/key", {link: true, source: "/this/is/a/key"}, (err) ->
      should(err).not.be.ok
      storage.get "this/is/another/key", (err, val) ->
        should(err).not.be.ok
        should(val.value).equal("key value")

  it "should not create circular link", ->
    storage.create "/this/is/a/key/sub", {link: true, source: "/this/is/a"}, (err) ->
      should(err).be.ok

  it "should update value", ->
    storage.update "/this/is/a/key", {data: "new key value"}, (err) ->
      should(err).not.be.ok
      storage.get "/this/is/a/key", (err, val) ->
        should(err).not.be.ok
        should(val.value).equal("new key value")
        storage.get "this/is/another/key", (err, val) ->
          should(err).not.be.ok
          should(val.value).equal("new key value")

  it "should not update link from value keys", ->
    storage.update "/this/is/a/key", {link: true, source: "/this/is/some/key/else"}, (err) ->
      should(err).be.ok

  it "should not update value from linked keys", ->
    storage.update "/this/is/another/key", {data: ""}, (err) ->
      should(err).be.ok

  it "should delete key", ->
    storage.delete "/this/is/a/key", (err) ->
      should(err).not.be.ok
      storage.get "this/is/a/key", (err, val) ->
        should(err).be.ok
        storage.get "this/is/another/key", (err, val) ->
          should(err).not.be.ok
          should(val.value).equal("new key value")

  it "should delete link key", ->
    storage.delete "/this/is/another/key", (err) ->
      storage.get "this/is/another/key", (err, val) ->
        should(err).be.ok
