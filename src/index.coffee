mongoose = require 'mongoose'

ConnectionStates =
  disconnected  : 0
  connected     : 1
  connecting    : 2
  disconnecting : 3

module.exports = databases =
  connections: {}
  callbacks: []

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
    @callbacks.push cb if cb?

    connectTo = (name, settings) =>
      url = settings.url
      options = settings.options

      finishOrRetry = (err, result) =>
        if err?
          settings.logger?.error err, "Failed to connect to `#{url}` on startup - retrying in 5 sec"
          setTimeout (-> connectTo name, settings), 5000
        else if Object.keys(@connections).every((connection) => @connections[connection].readyState is ConnectionStates.connected)
          callback() while callback = @callbacks.pop()

      if url.indexOf(',') >= 0
        @connections[name].openSet url, options, finishOrRetry
      else
        @connections[name].open url, options, finishOrRetry

    for name, connection of @connections
      switch connection.readyState
        when ConnectionStates.disconnected
          connectTo name, connection.settings
        when ConnectionStates.disconnecting
          throw new Error "Called connect() before disconnect() has finished"


  disconnect: (callback) ->
    mongoose.disconnect(callback)
