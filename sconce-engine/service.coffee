somata = require 'somata'
client = new somata.Client

DataService = client.remote.bind client, 'sconce:data'

createJob = (new_job, cb) ->
    create_job_query = '''
    mutation($create: JobInput!){
        create_job(create: $create){
            _id, name, params, hostname
        }
    }
    '''
    DataService 'query', create_job_query, {create: new_job}, (err, {create_job}) ->
        console.log 'created job', create_job
        service.publish "jobs", create_job
        cb err, create_job

createPoint = (job_id, point, cb) ->
    point.job_id = job_id
    point.t = new Date().getTime()
    service.publish "jobs:#{job_id}:points", point
    DataService 'create', 'points', point, cb

createLog = (job_id, log, cb) ->
    log.job_id = job_id
    log.t = new Date().getTime()
    service.publish "jobs:#{job_id}:logs", log
    DataService 'create', 'logs', log, cb

createResult = (job_id, result, cb) ->
    result.job_id = job_id
    DataService 'create', 'results', result, cb

service = new somata.Service 'sconce:engine', {
    createJob
    createPoint
    createLog
    createResult
}
