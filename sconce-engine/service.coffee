somata = require 'somata'
client = new somata.Client

DataService = client.remote.bind client, 'sconce:data'

createPoint = (job_id, point, cb) ->
    point.job_id = Number job_id
    point.t = new Date().getTime()
    service.publish "jobs:#{job_id}:points", point
    DataService 'create', 'points', point, cb

createLog = (job_id, log, cb) ->
    log.job_id = Number job_id
    log.t = new Date().getTime()
    service.publish "jobs:#{job_id}:logs", log
    DataService 'create', 'logs', log, cb

createResult = (job_id, result, cb) ->
    result.job_id = Number job_id
    DataService 'create', 'results', result, cb

service = new somata.Service 'sconce:engine', {
    createPoint
    createLog
    createResult
}
