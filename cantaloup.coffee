module.exports =
  load: ->
    yield [1,2,3]
    process.env.CANTALOUP = "true"
