COUCHDB = require 'couchdb-api'
Q = require 'q'

INVPARAM = 'INVPARAM'

# Use Object.create() to create a clean JavaScript object to hang the API
# methods on.
api = Object.create(null)


# Public: Fetch a document from the database.
#
# aId - The id String of the document to get.
#
# Returns a Q::Promise Object.
api.get = (aId) ->
    get_params(aId)

    d = Q.defer()
    revisions = @revisions
    couchdb = @couchdb
    @couchdb.doc(aId).get (err, body, res) ->
        if res.statusCode is 200
            doc = receiveDoc(@body, revisions)
            return d.resolve(doc)

        if res.statusCode is 404
            # There are two kinds of Not Found responses. One for a missing
            # database, and one for a missing document.
            if err and err.reason is 'no_db_file'
                msg = "api.get(aId) database '#{couchdb.name}' does not exist."
                err = new Error(errMessage(msg))
                err.code = 'ENODB'
                return d.reject(err)

            # Missing document.
            return d.resolve(null)

        # Assume all other cases are unexpected exceptions.
        return d.reject(new Error(couchdbErr(err)))

    return d.promise

# Private: Check parameters for api.get()
get_params = (aId) ->
    if isEmpty(aId)
        msg = errMessage("api.get(aId) aId is required.")
        throwInvParam(new Error(msg))

    if typeof aId isnt 'string'
        msg = errMessage("api.get(aId) aId must be a String.")
        throwInvParam(new Error(msg))

    return


# Public: Save a document to the database.
#
# aDoc = The JavaScript Object representing the document.
#
# Returns a Q::Promise Object.
api.set = (aDoc) ->
    set_params(aDoc)

    document = repr(aDoc)
    rev = @revisions[document._id]
    if rev then document._rev = rev

    d = Q.defer()
    revisions = @revisions
    couchdb = @couchdb
    @couchdb.doc(document).save (err, body, res) ->
        if res.statusCode is 201
            doc = receiveDoc(@body, revisions)
            return d.resolve(doc)

        if res.statusCode is 409
            err = new Error("Document conflict rejection id: #{@id}")
            err.code = 'CONFLICT'
            return d.reject(err)

        # In this case of a Not Found response, the missing database can be the
        # only culprit.
        if res.statusCode is 404
            msg = "api.set(aId) database '#{couchdb.name}' does not exist."
            err = new Error(errMessage(msg))
            err.code = 'ENODB'
            return d.reject(err)

        # Assume all other cases are unexpected exceptions.
        return d.reject(new Error(couchdbErr(err)))

    return d.promise

# Private: Check parameters for api.set()
set_params = (aDoc) ->
    if Object(aDoc) isnt aDoc
        msg = errMessage("api.set(aDoc) aDoc must be an Object.")
        throwInvParam(new Error(msg))

    if Object.keys(aDoc).length < 1
        msg = errMessage("api.set(aDoc) aDoc must not be an empty Object.")
        throwInvParam(new Error(msg))

    return


# Public: Delete a document from the database.
#
# aId - The id String of the document to delete.
#
# If the document has not been fetched with .get() or query() then an Error
# with code 'INVPARAM' will be thrown.
#
# Returns a Q::Promise Object.
api.remove = (aId) ->
    remove_params(aId)

    document = @couchdb.doc(aId)
    rev = @revisions[document.id]
    if rev then document.body = {_rev: rev}
    else
        msg = "A document must be fetched before "
        msg += "it can be removed with api.remove(aId)."
        throwInvParam(new Error(errMessage(msg)))

    d = Q.defer()
    revisions = @revisions
    document.del (err, body, res) ->
        if res.statusCode is 200
            delete revisions[body.id]
            return d.resolve(true)

        if res.statusCode is 404
            return d.resolve(false)

        if res.statusCode is 409
            err = new Error("Document conflict rejection id: #{@id}")
            err.code = 'CONFLICT'
            return d.reject(err)

        # Assume all other cases are unexpected exceptions.
        return d.reject(new Error(couchdbErr(err)))

    return d.promise

# Private: Check parameters for api.remove()
remove_params = (aId) ->
    if isEmpty(aId)
        msg = errMessage("api.remove(aId) aId is required.")
        throwInvParam(new Error(msg))

    if typeof aId isnt 'string'
        msg = errMessage("api.remove(aId) aId must be a String.")
        throwInvParam(new Error(msg))

    return


# Public: Query an index of documents based on a key range.
#
# aIndex - The name String of the index to query.
# aQuery - The Object hash of query parameters.
#          .key        - The key to use (may be String, Number, Null, or Array).
#          .limit      - The max Number of documents to include in the results.
#          .descending - A Boolean flag which can be used to reverse the
#                        order of the range scan (default: false).
#          .startkey   - The key to begin a range scan on
#                        (may be String, Number, Null, or Array).
#          .endkey     - The key to end a range scan on
#                        (may be String, Number, Null, or Array).
#
# It is assumed that the index has already been created through another
# channel.  If it hasn't, then the returned Q::Promise will reject with a
# 'NOTFOUND' Error.
#
# Returns a Q::Promise Object.
api.query = (aIndex, aQuery) ->
    query_params(aIndex, aQuery)

    d = Q.defer()
    revisions = @revisions
    couchdb = @couchdb
    view = @couchdb.designDoc('application').view(aIndex)
    view.query aQuery, (err, body, res) ->
        if res.statusCode is 200
            docs = body.rows.map (row) ->
                return receiveDoc(row.value, revisions)
            return d.resolve(docs)

        if res.statusCode is 404
            # There are two kinds of Not Found responses. One for a missing
            # database, and one for a missing design document.
            if err and err.reason is 'no_db_file'
                msg = "api.query(aId) database '#{couchdb.name}' does not exist."
                err = new Error(errMessage(msg))
                err.code = 'ENODB'
                return d.reject(err)

            # Missing design document.
            err = new Error("Index '#{aIndex}' not found.")
            err.code = 'NOTFOUND'
            return d.reject(err)

        # Assume all other cases are unexpected exceptions.
        return d.reject(new Error(couchdbErr(err)))

    return d.promise

# Private: Check parameters for api.query()
query_params = (aIndex, aQuery) ->
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


# Private: Utility for api functions that receive documents.
receiveDoc = (aIncoming, aRevisions) ->
    doc = repr(aIncoming)
    if doc._rev
        aRevisions[doc._id] = doc._rev
        delete doc._rev
    return doc


# Private: Normalize an object.
repr = do ->
    proto = Object.create(null)
    Object.defineProperty(proto, 'valueOf', {
        value: -> return @
    })

    convert = (a) ->
        if Object(a) isnt a then return a

        rv = Object.keys(a).reduce((rv, key) =>
            rv[key] = a[key]
            return rv
        , Object.create(proto))

        return rv

    return convert


# Private: Compose a CouchDB error string.
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
#         .creds    - An credentials Object hash.
#                     .username - The username String.
#                     .password - The password String.
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

    if aOpts.creds
        msg = null
        if Object(aOpts.creds) isnt aOpts.creds
            msg = errMessage('connect(aOpts) aOpts.creds must be an Object.')
        else if isEmpty(aOpts.creds.username)
            msg = errMessage('connect(aOpts) aOpts.creds.username must be a String.')
        else if isEmpty(aOpts.creds.password)
            msg = errMessage('connect(aOpts) aOpts.creds.password must be a String.')
        if msg then throwInvParam(new Error(msg))

    # couchdb-api requires a URL string to initialize
    url = if aOpts.secure then 'https://' else 'http://'
    if aOpts.creds
        url += "#{aOpts.creds.username}:#{aOpts.creds.password}@"
    url += aOpts.hostname
    if aOpts.port then url += ":" + aOpts.port
    else if aOpts.secure then url += ":443"
    else url += ":5984"

    couchdb = COUCHDB.srv(url).db(aOpts.database)

    # Use Object.create() and Object.defineProperty() to createa clean Object
    # for the caller.
    db = Object.create(api)
    Object.defineProperty(db, 'couchdb', {
        value: couchdb
    })
    Object.defineProperty(db, 'revisions', {
        value: Object.create({})
    })
    return db


# Private: Used for internal parameter checking.
isEmpty = (obj) ->
    return obj is '' or obj is undefined or obj is null


# Private: Used for internal parameter checking.
errMessage = (msg) ->
    return "enginemill-db::" + msg


# Private: Used for internal parameter checking.
throwInvParam = (err) ->
    return throwErr(err, INVPARAM)


# Private: Used for internal parameter checking.
throwErr = (err, code) ->
    err.code = code
    throw err
