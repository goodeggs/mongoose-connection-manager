fibrous = require 'fibrous'
mongoose = require 'mongoose'

module.exports = databases =
  connections: {}

  get: (name) ->
    @connections[name]

  exists: (name) ->
    @connections[name]?

  create: (name, settings) ->
    throw new Error "Connection name must be provided" unless name?
    throw new Error "Connection settings must be provided" unless settings?
    throw new Error "Connection url must be provided" unless settings.url

    if settings.useDefault
      @connections[name] = mongoose.connection
    else
      @connections[name] = mongoose.createConnection()

    @connections[name].settings = settings
    @connections[name]

  connect: (cb) ->
    connectTo = (name, settings, callback) =>
      url = settings.url
      options = settings.options

      finishOrRetry = (err, result) ->
        if err?
          settings.logger?.error err, "Failed to connect to `#{url}` on startup - retrying in 5 sec"
          setTimeout (-> connectTo name, settings, callback), 5000
        else
          callback()

      if url.indexOf ',' > 0
        @connections[name].openSet url, options, finishOrRetry
      else
        @connections[name].open url, options, finishOrRetry

    futures = []

    for name, connection of @connections
      if connection.readyState is 0
        futures.push connectTo.future name, connection.settings

    fibrous.run ->
      fibrous.wait futures
      cb?()

  disconnect: fibrous ->
    mongoose.sync.disconnect()
