require './support/test_helper'
manager = require '../lib/index'

mongoose = require 'mongoose'

describe '::mongoose-manager', ->
  beforeEach ->
    sinon.stub(mongoose.Connection::, 'open').callsArgAsync(2)
    sinon.stub(mongoose.Connection::, 'openSet').callsArgAsync(2)


  describe 'a single server and replica set connection', ->
    {singleServer, replicaSet} = {}

    beforeEach ->
      singleServer = 'mongodb://localhost'
      replicaSet = 'mongodb://localhost,mongodb://another-server'
      manager.create 'we-be-testin', { url: singleServer }
      manager.create 'mo-testin', { url: replicaSet }

    describe '.connect', ->
      it 'calls callback on successfull connection', (done) ->
        manager.connect done

      it 'calls open for single urls', ->
        manager.connect ->
          expect(mongoose.Connection::open.called).to.equal true
          expect(mongoose.Connection::open.args[0][0]).to.equal singleServer

      it 'calls openSet for multiple urls', ->
        manager.connect ->
          expect(mongoose.Connection::openSet.called).to.equal true
          expect(mongoose.Connection::openSet.args[0][0]).to.equal replicaSet


  describe 'a connection set that already exists', ->
    beforeEach ->
      manager.create 'we-be-testin', { url: 'mongodb://localhost' }
      manager.connect()

    it 'allows adding a second connection', (done) ->
      manager.create 'mo-testin', { url: 'mongodb://localhosty' }
      manager.connect done
