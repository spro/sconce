graphql = require 'graphql'
GraphQLJSON = require 'graphql-type-json'
schema = require './schema'

# Building the Schema

schema_types = {} # For easy reference to original parsed types
schema.map (schema_type) ->
    schema_types[schema_type.name] = schema_type

builtin_types =
    String: graphql.GraphQLString
    Int: graphql.GraphQLInt
    Float: graphql.GraphQLFloat
    JSON: GraphQLJSON

custom_types = {}
input_types = {}

schema.map (schema_type) ->
    custom_types[schema_type.name] = new graphql.GraphQLObjectType
        name: schema_type.name
        fields: ->
            fieldsForParsedFields schema_type.fields

schema.map (schema_type) ->
    input_types[schema_type.name + 'Input'] = new graphql.GraphQLInputObjectType
        name: schema_type.name + 'Input'
        fields: ->
            inputFieldsForParsedFields schema_type.fields

fieldsForParsedFields = (parsed_fields) ->
    fields = {}
    fields[schema.id_key] = {type: graphql.GraphQLID} # Everything has an ID by default

    parsed_fields.map (parsed_field) ->

        # Reference to a builtin type
        if builtin_type = builtin_types[parsed_field.type]
            fields[parsed_field.name] = type: builtin_type

        else
            # Add a regular ID field for get attachments, e.g. interaction.user_id
            if parsed_field.dir == '>'
                fields[parsed_field.key] = type: graphql.GraphQLID

            # Create the full type and resolver
            fields[parsed_field.name] = customFieldForParsedField parsed_field

    return fields

customFieldForParsedField = (parsed_field) ->
    {collection} = schema_types[parsed_field.type]
    Type = custom_types[parsed_field.type]
    InputType = input_types[parsed_field.type + 'Input']

    # Get attachments (>) look for an external object by id from self[key]
    if parsed_field.dir == '>'
        resolve = (self, args, context) ->
            query = {}
            query[schema.id_key] = self[parsed_field.key]
            if args.query?
                Object.assign query, args.query
            return getType context, collection, query

    # Find attachments (<) look for other objects matching obj[key] = self.id
    else if parsed_field.dir == '<'
        Type = new graphql.GraphQLList Type # Will return a list
        resolve = (self, args, context) ->
            query = {}
            query[parsed_field.key] = self[schema.id_key]
            if args.query?
                Object.assign query, args.query
            return findType context, collection, query

    return {
        type: Type
        args:
            query: type: InputType
        resolve
    }

inputFieldsForParsedFields = (parsed_fields) ->
    fields = {}
    parsed_fields.map (parsed_field) ->
        if builtin_type = builtin_types[parsed_field.type]
            fields[parsed_field.name] = type: builtin_type
        else if parsed_field.dir == '>'
            fields[parsed_field.key] = type: graphql.GraphQLID
    return fields

query_fields = {}
mutation_fields = {}

schema.map (schema_type) ->
    {singular, collection} = schema_type
    Type = custom_types[schema_type.name]
    InputType = input_types[schema_type.name + 'Input']
    get_args = {}
    get_args[schema.id_key] = type: graphql.GraphQLID
    update_args = update: type: InputType
    update_args[schema.id_key] = type: graphql.GraphQLID

    query_fields[singular] =
        type: Type
        args: get_args
        resolve: (_, args, context) ->
            getType(context, collection, args)

    query_fields[collection] =
        type: new graphql.GraphQLList Type
        args:
            query: type: InputType
        resolve: (_, {query}, context) ->
            findType(context, collection, query)

    mutation_fields['create_' + singular] =
        type: Type
        args:
            create: type: InputType
        resolve: (_, {create}, context) ->
            createType(context, collection, create)

    mutation_fields['update_' + singular] =
        type: Type
        args: update_args
        resolve: (_, args, context) ->
            update = args.update
            id = args[schema.id_key]
            updateType(context, collection, id, update)

QueryType = new graphql.GraphQLObjectType
    name: 'Query'
    fields: query_fields

MutationType = new graphql.GraphQLObjectType
    name: 'Mutation'
    fields: mutation_fields

graphql_schema = new graphql.GraphQLSchema
    query: QueryType
    mutation: MutationType

# Resolvers

## Promise helpers

promiseFromAsync = (fn) -> (args...) ->
    new Promise (resolve, reject) ->
        fn args..., (err, response) ->
            if response?
                resolve response
            else
                reject err

p = (fn, args...) -> promiseFromAsync(fn)(args...)

## Main CRUD methods, bound to DB passed in root context

getType = ({db}, collection, query={}) ->
    console.log '[getType]', collection, query
    p db.get, collection, query

findType = ({db}, collection, query={}) ->
    console.log '[findType]', collection, query
    p db.find, collection, query

createType = ({db}, collection, new_item) ->
    console.log '[createType]', collection, new_item
    p db.create, collection, new_item

updateType = ({db}, collection, id, item_update) ->
    console.log '[updateType]', collection, id, item_update
    p db.update, collection, id, item_update

# Queries

runQuery = (db, query, variables) ->
    graphql_root = {}
    graphql_context = {db}
    graphql.graphql(graphql_schema, query, graphql_root, graphql_context, variables)

module.exports =
    query: (db, query, variables, cb) ->
        if typeof variables == 'function' and !cb?
            cb = variables
            variables = {}
        runQuery(db, query, variables)
            .then ({errors, data}) ->
                cb errors, data

