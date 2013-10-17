require './support/test_helper'
manager = require '../lib/index'

mongoose = require 'mongoose'

describe '::mongoose-manager', ->
  beforeEach ->
    sinon.stub(mongoose.Connection::, 'open').callsArgAsync(2)
    sinon.stub(mongoose.Connection::, 'openSet').callsArgAsync(2)
    manager.create 'we-be-testin', { url: 'mongodb://localhost' }
    manager.create 'mo-testin', { url: 'mongodb://localhost,mongodb://another-server' }

  describe '.connect', ->
    it 'call callback on successfull connection', (done) ->
      manager.connect done
