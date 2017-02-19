polar = require 'somata-socketio'
config = require './config'

app = polar config
app.get '/', (req, res) -> res.render 'index', {config}
app.start()
