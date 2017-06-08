d3 = require 'd3'
tinycolor = require 'tinycolor2'

# Helpers

d3_color = d3.scaleOrdinal(d3.schemeCategory10)

color = (d) ->
    c = d3_color d
    tinycolor(c).lighten(20).toHexString()

oid2t = (oid) ->
    new Date(parseInt(oid.substring(0, 8), 16) * 1000)

module.exports = {
    color
    oid2t
}
