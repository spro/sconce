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

generateObject = (collection, id) ->
    if collection == 'users'
        name = randomChoice(names)
        email = randomChoice(emails)
        return {name, email, id}
    else
        random_number = Math.random()
        return {random_number, id}

generateCollection = (collection) ->
    [0..10].map generateObject.bind(null, collection)

module.exports = {
    generateObject
    generateCollection
}
