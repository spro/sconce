fs = require 'fs'
schema_string = fs.readFileSync('schema.sch', 'utf8').trim()

# Parsing the Schema

tokenizeSchema = (schema_string) ->
    schema_string.split('\n\n').map tokenizeSection

tokenizeSection = (section) ->
    section = section.split('\n')
    key = section.shift()
    lines = section.map (line) ->
        line.trim().split(' ')
    [key, lines]

parseSection = ([key, lines]) ->
    [name, collection] = key.split(' ')
    singular = name.toLowerCase()
    if !collection?
        collection = singular + 's'
    {
        name, singular, collection
        fields: lines.map parseLine
    }

parseLine = (line) ->
    if line.length == 2
        [name, type] = line
        {name, type}
    else
        [name, type, dir, key] = line
        {name, type, dir, key}

tokenized = tokenizeSchema schema_string
schema = tokenized.map parseSection
schema.id_key = '_id'

module.exports = schema
