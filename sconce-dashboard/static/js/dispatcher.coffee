fetch$ = require 'kefir-fetch'
KefirCollection = require 'kefir-collection'
somata = require 'somata-socketio-client'

fetch$.setDefaultOptions {base_url: config.api_base_url}

Store = {}

module.exports = Dispatcher =
    find: (type, query) ->
        Store[type] = KefirCollection()
        fetch$ 'get', "/#{type}.json", {query}
            # .onValue (items) -> items.reverse(); Store[type].setItems items
            .onValue (items) -> Store[type].setItems items
        Store[type]

    get: (type, id) ->
        fetch$ 'get', "/#{type}/#{id}.json"

    create: (type, new_item, id) ->
        fetch$ 'post', "/#{type}.json", {body: new_item}
            .onValue Store[type].createItem

    update: (type, id, item_update) ->
        fetch$ 'put', "/#{type}/#{id}.json", {body: item_update}
            .onValue (updated_item) -> Store[type].updateItem id, updated_item

    remove: (type, id) ->
        fetch$ 'delete', "/#{type}/#{id}.json"
            .onValue -> Store[type].removeItem id

    claimJob: (job_id, machine_id) ->
        fetch$ 'post', "/jobs/#{job_id}/claim.json", {body: {machine_id}}
            .onValue Store.jobs.updateItem.bind(null, job_id)

