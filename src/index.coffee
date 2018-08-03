ConnectionStates =
  disconnected  : 0
  connected     : 1
  connecting    : 2
  disconnecting : 3

###
instantiate w/ mongoose instance to avoid duplicate copies.
(e.g. breaks model creation when `npm link`ing)
###
module.exports = databases = (mongoose) ->
  if not mongoose?
    throw new Error('Mongoose is a required argument for mongoose-connection-manager!')

  connections: {}
  callbacks: []
  logger: null

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

  setLogger: (newLogger) ->
    @logger = newLogger

  connect: (cb) ->
    return process.nextTick(cb) if @allConnected()

    @callbacks.push cb if cb?

    connectTo = (name, settings) =>
      url = settings.url
      options = settings.options ? {}

      finishOrRetry = (err, result) =>
        if err?
          (settings.logger ? @logger)?.error err, "Failed to connect to `#{name}` database on startup - retrying in 5 sec"
          setTimeout (-> connectTo name, settings), 5000
        else if @allConnected()
          callback() while callback = @callbacks.pop()

      @connections[name].openUri url, options, finishOrRetry

    for name, connection of @connections
      switch connection.readyState
        when ConnectionStates.disconnected
          connectTo name, connection.settings
        when ConnectionStates.disconnecting
          throw new Error "Called connect() before disconnect() has finished"

  allConnected: ->
    Object.keys(@connections).every((connection) => @connections[connection].readyState is ConnectionStates.connected)

  disconnect: (callback) ->
    mongoose.disconnect(callback)
