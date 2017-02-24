names = [
    "Joe Jones"
    "Sally Salt"
    "Kendrick Kollins"
    "Charlie Chaplin"
]

emails = [
    "joejones@yahoo.com"
    "sallysalt@gmail.com"
    "kendrickkollins@yahoo.com"
    "charliechaplin@gmail.com"
]

randomChoice = (l) ->
    l[Math.floor Math.random() * l.length]

generateObject = (id_key, collection, id) ->
    if collection == 'users'
        name = randomChoice(names)
        email = randomChoice(emails)
        item = {name, email}
        item[id_key] = id
        return item
    else
        random_number = Math.random()
        item = {random_number}
        item[id_key] = id
        return item

generateCollection = (id_key, collection) ->
    [0..10].map generateObject.bind(null, id_key, collection)

module.exports = {
    generateObject
    generateCollection
}
