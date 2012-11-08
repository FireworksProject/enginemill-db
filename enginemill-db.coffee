COUCHDB = require 'couchdb-api'
Q = require 'q'

INVPARAM = 'INVPARAM'

api = Object.create(null)


api.get = (aId) ->
    if isEmpty(aId)
        msg = errMessage("api.get(aId) aId is required.")
        throwInvParam(new Error(msg))

    if typeof aId isnt 'string'
        msg = errMessage("api.get(aId) aId must be a String.")
        throwInvParam(new Error(msg))

    d = Q.defer()
    @couchdb.doc(aId).get (err, body, res) ->
        if not err and res.statusCode is 200
            doc = repr(body)
            delete doc._rev
            return d.resolve(doc)
        if res.statusCode is 404
            return d.resolve(null)
        return d.reject(new Error(couchdbErr(err)))

    return d.promise


api.set = (aDoc) ->
    if Object(aDoc) isnt aDoc
        msg = errMessage("api.set(aDoc) aDoc must be an Object.")
        throwInvParam(new Error(msg))

    if Object.keys(aDoc).length < 1
        msg = errMessage("api.set(aDoc) aDoc must not be an empty Object.")
        throwInvParam(new Error(msg))

    d = Q.defer()
    @couchdb.doc(aDoc).save (err, body, res) ->
        if not err and res.statusCode is 201
            doc = repr(@body)
            delete doc._rev
            return d.resolve(doc)
        if res.statusCode is 409
            err = new Error("Document conflict rejection id: #{@id}")
            err.code = 'CONFLICT'
            return d.reject(err)

    return d.promise


api.remove = (aId) ->
    if isEmpty(aId)
        msg = errMessage("api.remove(aId) aId is required.")
        throwInvParam(new Error(msg))

    if typeof aId isnt 'string'
        msg = errMessage("api.remove(aId) aId must be a String.")
        throwInvParam(new Error(msg))

    return


api.query = (aIndex, aQuery) ->
    if isEmpty(aIndex)
        msg = errMessage("api.query(aIndex, aQuery) aIndex is required.")
        throwInvParam(new Error(msg))

    if typeof aIndex isnt 'string'
        msg = errMessage("api.query(aIndex, aQuery) aIndex must be a String.")
        throwInvParam(new Error(msg))

    if aQuery and Object(aQuery) isnt aQuery
        msg = "api.query(aIndex, aQuery) if passed, aQuery must be an Object."
        msg = errMessage(msg)
        throwInvParam(new Error(msg))

    if aQuery and Object.keys(aQuery).length < 1
        msg = "api.query(aIndex, aQuery) if passed, aQuery must "
        msg += "not be an empty Object."
        msg = errMessage(msg)
        throwInvParam(new Error(msg))
    return


repr = do ->
    proto = Object.create(null)
    Object.defineProperty(proto, 'valueOf', {
        value: -> return @
    })

    convert = (a) ->
        if Object(a) isnt a or typeof a.valueOf is 'function'
            return a

        rv = Object.keys(a).reduce((rv, key) =>
            rv[key] = a[key]
            return rv
        , Object.create(proto))

        return rv

    return convert


couchdbErr = (aErr) ->
    msg = "CouchDB engine error: "
    if aErr.error and aErr.reason
        msg += "#{aErr.error}, reason: #{aErr.reason}"
    else if aErr.code is 'ECONNREFUSED'
        msg += "HTTP Connection refused."
    else if aErr.message then msg += aErr.message
    else msg += aErr.toString()
    return msg


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
        msg = errMessage('connect(aOpts) aOpts.hostname is required.')
        throwInvParam(new Error(msg))

    else if typeof aOpts.hostname isnt 'string'
        msg = errMessage('connect(aOpts) aOpts.hostname must be a String.')
        throwInvParam(new Error(msg))

    if aOpts.port and typeof aOpts.port isnt 'number'
        msg = errMessage('connect(aOpts) aOpts.port must be a Number.')
        throwInvParam(new Error(msg))

    if isEmpty(aOpts.database)
        msg = errMessage('connect(aOpts) aOpts.database is required.')
        throwInvParam(new Error(msg))

    else if typeof aOpts.database isnt 'string'
        msg = errMessage('connect(aOpts) aOpts.database must be a String.')
        throwInvParam(new Error(msg))

    url = if aOpts.secure then 'https://' else 'http://'
    url += aOpts.hostname
    if aOpts.port then url += ":" + aOpts.port
    else if aOpts.secure then url += ":443"
    else url += ":5984"

    couchdb = COUCHDB.srv(url).db(aOpts.database)

    db = Object.create(api)
    Object.defineProperty(db, 'couchdb', {
        value: couchdb
    })
    return db


isEmpty = (obj) ->
    return obj is '' or obj is undefined or obj is null


errMessage = (msg) ->
    return "enginemill-db::" + msg


throwInvParam = (err) ->
    return throwErr(err, INVPARAM)


throwErr = (err, code) ->
    err.code = code
    throw err
