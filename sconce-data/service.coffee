DataService = require 'data-service'

new DataService 'sconce:data', {
    type: 'mongo'
    config: db: 'sconce'
}
