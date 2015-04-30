require './support/test_helper'

mongoose = require 'mongoose'
manager = require('../lib/index')(mongoose)

describe '::mongoose-manager', ->
  connectionStub = (url, options, callback) ->
    @readyState = 1
    process.nextTick callback

  beforeEach ->
    sinon.stub(mongoose.Connection::, 'open', connectionStub)
    sinon.stub(mongoose.Connection::, 'openSet', connectionStub)


  describe 'a single server and replica set connection', ->
    {singleServer, replicaSet} = {}

    beforeEach ->
      singleServer = 'mongodb://localhost'
      replicaSet = 'mongodb://localhost,mongodb://another-server'
      manager.create 'we-be-testin', { url: singleServer }
      manager.create 'mo-testin', { url: replicaSet }

    describe '.connect', ->
      it 'calls callback on successful connection', (done) ->
        manager.connect done

      it 'calls open for single urls', (done) ->
        manager.connect ->
          expect(mongoose.Connection::open.called).to.equal true
          expect(mongoose.Connection::open.args[0][0]).to.equal singleServer
          done()

      it 'calls openSet for multiple urls', (done) ->
        manager.connect ->
          expect(mongoose.Connection::openSet.called).to.equal true
          expect(mongoose.Connection::openSet.args[0][0]).to.equal replicaSet
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
