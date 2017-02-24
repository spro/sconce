Db = require './db'
{objectMatcher} = require './helpers'
{generateCollection} = require './generate'
try
    default_collections = require './data/collections.json'
catch e
    default_collections = {}

fixIds = (id_key, o) ->
    for k, v of o
        if k == id_key or k.match /_id$/
            o[k] = Number v

class LocalDb extends Db
    constructor: (@schema) ->
        @collections = default_collections
        for type in @schema
            if !@collections[type.collection]?
                @collections[type.collection] = generateCollection @schema.id_key, type.collection
        super

    _get: (type, query, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixIds @schema, query
        console.log '[LocalDb._get]', type, query
        item = @collections[type].filter(objectMatcher query)[0]
        cb null, item

    _find: (type, query, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixIds @schema.id_key, query
        console.log '[LocalDb._find]', type, query
        items = @collections[type].filter objectMatcher query
        cb null, items

    _findWithArray: (type, queries, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        found = []
        for item in  @collections[type]
            matches = false
            for query in queries
                if objectMatcher(query)(item)
                    matches = true
            if matches
                found.push item
        cb null, found

    _create: (type, new_item, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixIds @schema.id_key, new_item
        new_item[@schema.id_key] = @collections[type].slice(-1)[0]?[@schema.id_key] + 1 or 0
        @collections[type].push new_item
        cb null, new_item

    _update: (type, id, item_update, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        id = Number id
        fixIds @schema.id_key, item_update
        item = @collections[type].filter((i) -> i[@schema.id_key] == id)[0]
        Object.assign item, item_update
        cb null, item

    _remove: (type, id, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        id = Number id
        @collections[type] = @collections[type].filter((i) -> i[@schema.id_key] != id)
        cb null, true

module.exports = LocalDb
