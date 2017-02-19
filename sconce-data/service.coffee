somata = require 'somata'
schema = require './schema'

if process.argv[2] == 'pg'
    PostgresDb = require './postgres-db'
    db = new PostgresDb schema

else if process.argv[2] == 'mongo'
    MongnDb = require './mongo-db'
    db = new MongnDb schema

else
    LocalDb = require './local-db'
    db = new LocalDb schema

claimJob = (job_id, {machine_id}, cb) ->
    db.get 'jobs', job_id, (err, job) ->
        if job.machine_id?
            cb "Already assigned to machine #{machine_id}"
        else
            db.update 'jobs', job_id, {machine_id, start_time: new Date().getTime(), status: 'in progress'}, cb

service = new somata.Service 'sconce:data', {
    get: db.get.bind db
    find: db.find.bind db
    create: db.create.bind db
    update: db.update.bind db
    remove: db.remove.bind db
    claimJob
}
