require './support/test_helper'

mongoose = require 'mongoose'
manager = require('../lib/index')(mongoose)

describe '::mongoose-manager', ->
  describe 'connect success', ->
    connectionStub = (url, options, callback) ->
      @readyState = 1
      process.nextTick callback

    beforeEach ->
      sinon.stub(mongoose.Connection::, 'openUri').callsFake(connectionStub)

    describe 'a single server and replica set connection', ->
      {singleServer, replicaSet} = {}

      beforeEach ->
        singleServer = 'mongodb://username:password@localhost'
        replicaSet = 'mongodb://username:password@localhost,another-server'
        manager.create 'we-be-testin', { url: singleServer }
        manager.create 'mo-testin', { url: replicaSet }

      describe '.connect', ->
        it 'calls callback on successful connection', (done) ->
          manager.connect done

        it 'calls openUri for single urls', (done) ->
          manager.connect ->
            expect(mongoose.Connection::openUri.called).to.equal true
            expect(mongoose.Connection::openUri.args[0][0]).to.equal singleServer
            done()

        it 'calls openUri for multiple urls', (done) ->
          manager.connect ->
            expect(mongoose.Connection::openUri.called).to.equal true
            expect(mongoose.Connection::openUri.args[1][0]).to.equal replicaSet
            done()

    describe 'a connection set that already exists and is open', ->
      beforeEach ->
        manager.create 'we-be-testin', { url: 'mongodb://localhost' }
        manager.connect()

      it 'allows adding a second connection', (done) ->
        manager.create 'mo-testin', { url: 'mongodb://localhosty' }
        manager.connect done


    describe 'a connection set that isn‘t open', ->
      beforeEach ->
        manager.create 'we-be-testin', { url: 'mongodb://localhost' }

      it 'connects once despite attempts to open many times', (done) ->
        manager.connect()
        manager.connect done

      it 'calls callback immediately if everything is already open', (done) ->
        manager.connect()
        process.nextTick( -> manager.connect done )

  describe 'a connect error', ->
    {url, logger, username, password, databaseConfigName, connect, err} = {}

    beforeEach ->
      sinon.useFakeTimers()
      logger = sinon.stub {error: (->), warn: (->), info: (->), debug: (->)}
      username = 'someUsername'
      password = 'somePassword'
      databaseConfigName = 'someDatabase'

      err = new Error('unable to connect')

      sinon.stub(mongoose.Connection::, 'openUri')

      url = "mongodb://#{username}:#{password}@localhost/db-name"

      # tricky to stub out a failed open followed by a success which also mutates the connection state
      connect = (cb) ->
        manager.connect cb

        connection = manager.connections[databaseConfigName]
        expect(connection).to.be.ok()

        # first return with an error
        connection.openUri.yield(err)
        # then return with success that also changes readyState
        connection.readyState = 1
        connection.openUri.yield()

    describe 'with a logger passed in via settings', ->
      beforeEach ->
        manager.create databaseConfigName, { url, logger }

      it 'logs an error', (done) ->
        connect ->
          expect(logger.error.callCount).to.equal 1
          expect(logger.error.firstCall.args[0]).to.equal err
          expect(logger.error.firstCall.args[1]).to.contain(databaseConfigName)
          done()

      it 'does not leak credentials out to the logs', (done) ->
        connect ->
          expect(logger.error.callCount).to.equal 1
          expect(logger.error.firstCall.args[1]).not.to.contain(username)
          expect(logger.error.firstCall.args[1]).not.to.contain(password)
          done()

    describe 'with a logger passed in later via setLogger', ->
      beforeEach ->
        manager.create databaseConfigName, { url }
        manager.setLogger(logger)

      it 'logs an error', (done) ->
        connect ->
          expect(logger.error.callCount).to.equal 1
          expect(logger.error.firstCall.args[0]).to.equal err
          expect(logger.error.firstCall.args[1]).to.contain(databaseConfigName)
          done()
