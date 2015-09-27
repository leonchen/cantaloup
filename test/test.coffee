co = require 'co'
co ->
  yield require('../cantaloup').load()

  console.log process.env.CANTALOUP
