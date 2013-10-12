fibrous = require 'fibrous'
mongoose = require 'mongoose'

module.exports = databases =
  connectionExists: (name) ->
    @[name]?

  createConnection: (name, settings) ->
    @[name] = mongoose.createConnection()
    @[name].settings = settings

  connect: (cb) ->
    connectTo = (name, settings, callback) =>
      url = settings.url
      options = settings.options

      finishOrRetry = (err, result) ->
        if err?
          settings.logger?.error err, "Failed to connect to `#{url}` on startup - retrying in 5 sec"
          setTimeout (-> connectTo name, callback), 5000
        else
          callback()

      if url.indexOf ',' > 0
        @[name].openSet url, options, finishOrRetry
      else
        @[name].open url, options, finishOrRetry

    futures = []

    for name, connection of @
      if connection.readyState is 0
        futures.push connectTo.future name, connection.settings

    fibrous.run ->
      fibrous.wait futures
      cb?()

  disconnect: fibrous ->
    mongoose.sync.disconnect()
