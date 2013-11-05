require './support/test_helper'
manager = require '../lib/index'

mongoose = require 'mongoose'

describe '::mongoose-manager', ->
  {singleServer, replicaSet} = {}

  beforeEach ->
    singleServer = 'mongodb://localhost'
    replicaSet = 'mongodb://localhost,mongodb://another-server'
    sinon.stub(mongoose.Connection::, 'open').callsArgAsync(2)
    sinon.stub(mongoose.Connection::, 'openSet').callsArgAsync(2)
    manager.create 'we-be-testin', { url: singleServer }
    manager.create 'mo-testin', { url: replicaSet }

  describe '.connect', ->
    it 'call callback on successfull connection', (done) ->
      manager.connect done

    it 'calls open for single urls', ->
      manager.connect ->
        expect(mongoose.Connection::open.called).to.equal true
        expect(mongoose.Connection::open.args[0][0]).to.equal singleServer

    it 'calls openSet for multiple urls', ->
      manager.connect ->
        expect(mongoose.Connection::openSet.called).to.equal true
        expect(mongoose.Connection::openSet.args[0][0]).to.equal replicaSet
