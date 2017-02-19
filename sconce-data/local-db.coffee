Db = require './db'
{generateCollection} = require './generate'
try
    default_collections = require './data/collections.json'
catch e
    default_collections = {}

class LocalDb extends Db
    constructor: (@schema) ->
        @collections = default_collections
        for type, sub_types of @schema
            if !@collections[type]?
                @collections[type] = generateCollection type
        super

    _get: (type, id, cb) ->
        id = Number id
        console.log '[LocalDb._get]', type, id
        item = @collections[type].filter((i) -> i.id == id)[0]
        cb null, item

    _find: (type, query, cb) ->
        for k, v of query
            if k.match /_id$/
                query[k] = Number v
        console.log '[LocalDb._find]', type, query
        items = @collections[type].map (o) -> JSON.parse JSON.stringify o
        cb null, items.filter @matchQuery query

    _create: (type, new_item, cb) ->
        for k, v of new_item
            if k.match /_id$/
                new_item[k] = Number v
        new_item.id = @collections[type].slice(-1)[0]?.id + 1 or 0
        @collections[type].push new_item
        cb null, new_item

    _update: (type, id, item_update, cb) ->
        id = Number id
        item = @collections[type].filter((i) -> i.id == id)[0]
        Object.assign item, item_update
        cb null, item

    _remove: (type, id, cb) ->
        id = Number id
        @collections[type] = @collections[type].filter((i) -> i.id != id)
        cb null, true

module.exports = LocalDb
