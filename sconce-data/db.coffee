async = require 'async'
{isNullObject, hasNullKeys} = require './helpers'

class Db
    constructor: (@schema) ->
        console.log "Created #{@constructor.name} with schema:"
        @schema_by_collection = {}
        for type in @schema
            @schema_by_collection[type.collection] = type
            console.log " * #{type.name} (#{type.collection})"

    get: (type, query, cb) ->
        # console.log '[Db.get]', type, query
        if isNullObject query
            return cb "Missing required field 'query'"
        else if hasNullKeys query
            return cb "Query has null keys"
        else
            @_get type, query, cb

    find: (type, query, cb) ->
        # console.log '[Db.find]', type, query
        @_find type, query, cb

    findWithArray: (type, queries, cb) ->
        # console.log '[Db.findWithArray]', type, queries
        @_findWithArray type, queries, cb

    create: (type, new_item, cb) ->
        @schema_by_collection[type]?.preCreate?(new_item)
        @_create type, new_item, (err, created_item) =>
            if err?
                return cb err
            get_query = {}
            get_query[@schema.id_key] = created_item[@schema.id_key]
            @get type, get_query, (err, created_item) =>
                @schema_by_collection[type]?.postCreate?(created_item)
                cb err, created_item

    update: (type, id, item_update, cb) ->
        if !id?
            return cb "Missing required field 'id'"
        else
            @_update type, id, item_update, (err, updated_item) =>
                get_query = {}
                get_query[@schema.id_key] = updated_item[@schema.id_key]
                @get type, get_query, cb

    remove: (type, id, cb) ->
        @_remove type, id, cb

    bindAll: ->
        get: @get.bind @
        find: @find.bind @
        create: @create.bind @
        update: @update.bind @
        remove: @remove.bind @
        findWithArray: @findWithArray.bind @

module.exports = Db
