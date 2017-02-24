Db = require './db'
mongo = require 'mongodb'

fixIds = (o) ->
    for k, v of o
        if k.match /_id$/
            o[k] = mongo.ObjectId v

class MongoDb extends Db
    constructor: (@schema, @config={}) ->
        @db = new mongo.Db(
            @config.db or 'testdb',
            mongo.Server(@config.host or 'localhost', @config.port or 27017),
            safe: true
        )
        @db.open()
        super

    _get: (type, query, cb) ->
        fixIds query
        # console.log '[MongoDb._get]', type, query
        @db.collection(type).findOne query, cb

    _find: (type, query, cb) ->
        fixIds query
        # console.log '[MongoDb._find]', type, query
        @db.collection(type).find(query).toArray cb

    _findWithArray: (type, queries, cb) ->
        queries.map fixIds
        # console.log '[MongoDb._findWithArray]', type, queries
        @db.collection(type).find({$or: queries}).toArray cb

    _create: (type, new_item, cb) ->
        fixIds new_item
        # console.log '[MongoDb._create]', type, new_item
        @db.collection(type).insert new_item, (err, created) ->
            cb err, created?.ops[0]

    _update: (type, _id, item_update, cb) ->
        _id = mongo.ObjectId _id
        # console.log '[MongoDb._update]', type, _id, item_update
        query = {_id}
        options = {new: true}
        @db.collection(type).findAndModify query, null, item_update, options, (err, modified) ->
            cb err, modified?.value

    _remove: (type, _id, cb) ->
        _id = mongo.ObjectId _id
        # console.log '[MongoDb._remove]', type, _id
        query = {_id}
        @db.collection(type).remove query, (err, removed) ->
            cb err, removed?.result

module.exports = MongoDb
