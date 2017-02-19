async = require 'async'

descend = (o, ks) ->
    if typeof ks == 'string'
        ks = ks.split('.')
    if ks.length == 0
        return o
    else
        descend o[ks[0]], ks.slice(1)

class Db
    constructor: (@schema) ->
        console.log "Created #{@constructor.name} with schema:"
        for type, definition of @schema
            console.log " * #{type}"

    get: (type, id, cb) ->
        @_get type, id, (err, item) =>
            @getAttachments type, item, (err, item) ->
                cb err, item

    find: (type, query, cb) ->
        @_find type, query, (err, items) =>
            getAttachments = @getAttachments.bind @, type
            async.map items, getAttachments, cb

    create: (type, new_item, cb) ->
        @_create type, new_item, (err, created_item) =>
            @get type, created_item.id, cb

    update: (type, id, item_update, cb) ->
        @_update type, id, item_update, (err, updated_item) =>
            @get type, id, cb

    remove: (type, id, cb) ->
        @_remove type, id, cb

    matchQuery: (query) -> (item) ->
        matches = true
        for key, value of query
            if descend(item, key) != value
                matches = false
        return matches

    getAttachments: (type, item, cb) ->
        if item? and attachments = @schema[type]?._
            @getAttachmentsFrom attachments, type, item, cb

        else
            cb null, item

    getAttachmentsFrom: (attachments, type, item, cb) ->
        attach = (attachment, attach_key, cb) =>
            if !attachment.id_key? and !attachment.reverse_id_key?
                attachment.id_key = attach_key + '_id'

            if id_key = attachment.id_key
                attachment_type = attachment.type || attach_key + 's'
                @_get attachment_type, item[id_key], (err, attachment_item) =>
                    if attachment_item? and sub_attachments = attachment._
                        @getAttachmentsFrom sub_attachments, attachment_type, attachment_item, cb
                    else
                        cb err, attachment_item

            else if reverse_id_key = attachment.reverse_id_key
                attachment_type = attachment.type || attach_key
                query = {}
                query[reverse_id_key] = Number item.id

                @_find attachment_type, query, (err, attachment_items) =>
                    if sub_attachments = attachment._
                        subAttachTo = @getAttachmentsFrom.bind(@, sub_attachments, attachment_type)
                        async.map attachment_items, subAttachTo, cb
                    else
                        cb err, attachment_items

            else
                cb null

        async.mapValues attachments, attach, (err, attached) ->
            cb err, Object.assign {}, item, attached

module.exports = Db
