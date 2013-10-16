manager = require './index.coffee'

settings =
  url: 'mongodb://localhost'
  logger:
    error: (err, message) ->
      console.log 'Oh crap!'
      console.log err
      console.log message

manager.create 'we-be-testin', settings
manager.create 'mo-testin', settings
manager.create 'even-mo-testin', settings

manager.connect (error)->
  console.log error if error
  manager.disconnect (err) ->
    console.log if err then err else 'OK'
