somata = require 'somata'
schema = require './schema'
graphql = require './graphql'

if db_type = process.argv[2]
    if db_type == 'pg'
        PostgresDb = require './postgres-db'
        db = new PostgresDb schema

    if db_type == 'mongo'
        MongoDb = require './mongo-db'
        db = new MongoDb schema,
            db: 'sconce'

    else
        console.error "Unknown database type #{db_type}"
        process.exit()

else
    LocalDb = require './local-db'
    db = new LocalDb schema

db = db.bindAll()
db.query = graphql.query.bind null, db

service = new somata.Service 'sconce:data', db
