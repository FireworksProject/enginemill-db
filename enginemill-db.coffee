COUCHDB = require 'couchdb-api'

INVPARAM = 'INVPARAM'

api = Object.create(null)

api.get = () ->
    return

api.set = () ->
    return

api.remove = () ->
    return

api.query = () ->
    return

exports.api = api


# Public: Create a database connection
#
# aOpts - An options Object hash
#         .hostname - The String hostname of the CouchDB server.
#         .port     - The port Number to use (default: 5984 if aOpts.secure is
#                     false, and 443 if it is true).
#         .database - The String database name to use.
#         .secure   - A boolean flag to indicate the connection should be
#                     secure (default: false).
#
# Returns a database API Object.
#
# Throws Error objects with code 'INVPARAM' if any invalid parameters are
# passed or required parameters are missing.
exports.connect = (aOpts) ->
    if isEmpty(aOpts.hostname)
        msg = errMessage('connect() aOpts.hostname is required.')
        throwErr(new Error(msg), INVPARAM)

    else if typeof aOpts.hostname isnt 'string'
        msg = errMessage('connect() aOpts.hostname must be a String.')
        throwErr(new Error(msg), INVPARAM)

    if aOpts.port and typeof aOpts.port isnt 'number'
        msg = errMessage('connect() aOpts.port must be a Number.')
        throwErr(new Error(msg), INVPARAM)

    if isEmpty(aOpts.database)
        msg = errMessage('connect() aOpts.database is required.')
        throwErr(new Error(msg), INVPARAM)

    else if typeof aOpts.database isnt 'string'
        msg = errMessage('connect() aOpts.database must be a String.')
        throwErr(new Error(msg), INVPARAM)

    url = if aOpts.secure then 'https://' else 'http://'
    url += aOpts.hostname
    if aOpts.port then url += ":" + aOpts.port
    else if aOpts.secure then url += ":443"
    else url += ":5984"

    couchdb = COUCHDB.srv(url).database(aOpts.database)

    db = Object.create(api)
    Object.defineProperty(db, 'couchdb', {
        value: couchdb
    })
    return Object.freeze(db)


isEmpty = (obj) ->
    return obj is '' or obj is undefined or obj is null


errMessage = (msg) ->
    return "enginemill-db::" + msg

throwErr = (err, code) ->
    err.code = code
    throw err
