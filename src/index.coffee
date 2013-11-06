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
    all = (hash) ->
      for name, value of hash
        if not value
          return false
      true

    connectTo = (name, settings, callback) =>
      url = settings.url
      options = settings.options

      finishOrRetry = (err, result) ->
        if err?
          settings.logger?.error err, "Failed to connect to `#{url}` on startup - retrying in 5 sec"
          setTimeout (-> connectTo name, settings, callback), 5000
        else
          connected[name] = true
          cb?() if all connected

      if url.indexOf(',') >= 0
        @connections[name].openSet url, options, finishOrRetry
      else
        @connections[name].open url, options, finishOrRetry

    connected = {}

    for name, connection of @connections
      if connection.readyState is 0
        connected[name] = false
        connectTo name, connection.settings

  disconnect: (callback) ->
    mongoose.disconnect(callback)
