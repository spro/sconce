somata = require 'somata-socketio-client'
reload = -> window.location.reload(true)
somata.subscribe$('reloader', 'reload').onValue reload
