URL = require 'url'
HTTP = require 'http'

TOOLS = require 'test-tools'
T = TOOLS.test
_ = TOOLS.underscore

EDB = require '../dist/enginemill-db'

CDB = require '../dist/node_modules/couchdb-api/'

OPTS =
    hostname: 'localhost'
    port: 5985
    database: 'test_db'
    secure: false


describe 'connect()', ->
    COUCHDB_srv = CDB.srv

    after (done) ->
        CDB.srv = COUCHDB_srv
        return done()


    it 'should create a database connection', T (done) ->
        @expectCount(9)
        opts = _.clone(OPTS)
        opts.hostname = 'example.com'
        opts.secure = true
        delete opts.port

        mockDB = {}

        t = @

        CDB.srv = (urlString) ->
            url = URL.parse(urlString)
            t.equal(url.protocol, 'https:', 'url protocol')
            t.equal(url.hostname, 'example.com', 'url hostname')
            t.equal(url.port, '443', 'url port')
            return {db: database}

        database = (name) ->
            t.equal(name, 'test_db', 'database name')
            return mockDB

        db = EDB.connect(opts)
        @assert(_.isFunction(db.get), 'db.get')
        @assert(_.isFunction(db.set), 'db.set')
        @assert(_.isFunction(db.remove), 'db.remove')
        @assert(_.isFunction(db.query), 'db.query')

        # Check private property is not writable
        db.couchdb = {}
        @strictEqual(db.couchdb, mockDB, 'db.couchdb')
        return done()


    it 'should raise an exception if aOpts.hostname is missing', T (done) ->
        opts = _.clone(OPTS)
        delete opts.hostname

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.hostname is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.hostname isnt a String', T (done) ->
        opts = _.clone(OPTS)
        opts.hostname = 80

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.hostname must be a String.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.port is truthy but not a number', T (done) ->
        opts = _.clone(OPTS)
        opts.port = '5984'

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.port must be a Number.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.database is missing', T (done) ->
        opts = _.clone(OPTS)
        opts.database = ''

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.database is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.database isnt a String', T (done) ->
        opts = _.clone(OPTS)
        opts.database = false

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.database must be a String.', 'message')

        @expectCount(2)
        return done()

    return


describe 'api.get(aId)', ->
    gServer = null

    before (done) ->
        gServer = createCouchDBServer()
        gServer.start(done)
        return

    after (done) ->
        gServer.stop()
        return done()


    it 'should raise an exception if aId is missing', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.get()
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.get(aId) aId is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aId isnt a String', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.get({})
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.get(aId) aId must be a String.', 'message')

        @expectCount(2)
        return done()


    it 'should return a document', T (done) ->
        @expectCount(4)
        t = @

        handler = (req, res) ->
            t.equal(req.url, '/test_db/123abc', 'request url')
            res.statusCode = 200
            document = {_id: '123abc', field_1: 1, _rev: '1234567'}
            res.end(JSON.stringify(document))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.equal(doc._id, '123abc', 'returned document')
            t.equal(doc._rev, undefined, '._rev')
            t.equal(doc.field_1, 1, '.field_1')
            return done()

        EDB.connect(OPTS).get('123abc').then(success, done).done()
        return


    it 'should return null if the document does not exist', T (done) ->
        @expectCount(1)
        t = @

        handler = (req, res) ->
            res.statusCode = 404
            res.end(JSON.stringify({error: 'not_found', reason: 'missing'}))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.strictEqual(doc, null, 'returned null')
            return done()

        EDB.connect(OPTS).get('foo').then(success, done).done()
        return


    it 'should reject if there was a problem', T (done) ->
        @expectCount(1)
        t = @

        handler = (req, res) ->
            res.statusCode = 500
            res.end(JSON.stringify({error: 'failed', reason: 'unknown'}))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.assert(false, 'success() should not be called')
            return done()

        failure = (err) ->
            t.equal(err.message, 'CouchDB engine error: failed, reason: unknown', 'error message')
            return done()

        EDB.connect(OPTS).get('foo').then(success, failure).done()
        return

    return


describe 'api.set(aDoc)', ->
    gServer = null

    before (done) ->
        gServer = createCouchDBServer()
        gServer.start(done)
        return

    after (done) ->
        gServer.stop()
        return done()


    it 'should raise an exception if aDoc isnt an Object', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.set('foo')
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.set(aDoc) aDoc must be an Object.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aDoc is an empty Object', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.set({})
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.set(aDoc) aDoc must not be an empty Object.', 'message')

        @expectCount(2)
        return done()


    it 'should set an existing document', T (done) ->
        @expectCount(7)
        t = @
        document = {_id: 'awesomedoc', field_1: 1}

        handler = (req, res) ->
            t.equal(req.body._id, 'awesomedoc', 'PUT _id')
            t.equal(req.body.field_1, 1, 'PUT field_1')
            t.equal(req.method, 'PUT', 'http method')
            t.equal(req.url, '/test_db/awesomedoc', 'http url')
            res.statusCode = 201
            rv =
                id: document._id
                rev: '1234567'
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.equal(doc._id, 'awesomedoc', '._id')
            t.equal(doc._rev, undefined, '._rev')
            t.equal(doc.field_1, 1, 'field_1')
            return done()

        EDB.connect(OPTS).set(document).then(success, done).done()
        return

    return


describe 'api.remove(aId)', ->

    it 'should raise an exception if aId is missing', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.remove()
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.remove(aId) aId is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aId isnt a String', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.remove(12345)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.remove(aId) aId must be a String.', 'message')

        @expectCount(2)
        return done()

    return


describe 'api.query(aIndex, aQuery)', ->

    it 'should raise an exception if aIndex is missing', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.query('')
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.query(aIndex, aQuery) aIndex is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aIndex isnt a String', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.query(12345)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.query(aIndex, aQuery) aIndex must be a String.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aQuery is passed but isnt an Object', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.query('index_name', 'some_string')
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.query(aIndex, aQuery) if passed, aQuery must be an Object.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aQuery is passed but is an empty Object', T (done) ->
        opts = _.clone(OPTS)
        api = EDB.connect(opts)

        try
            api.query('index_name', {})
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::api.query(aIndex, aQuery) if passed, aQuery must not be an empty Object.', 'message')

        @expectCount(2)
        return done()


    return


createCouchDBServer = ->
    self = Object.create(null)
    server = HTTP.createServer()
    fRunning = false

    self.start = (aCallback) ->
        if fRunning
            msg = "CouchDB server is already running."
            return aCallback(new Error(msg))

        server.once 'error', (err) ->
            console.log('MOCK COUCHDB SERVER ERR EVENT', err)
            return aCallback(err)

        server.listen 5985, 'localhost', ->
            fRunning = true
            return aCallback()
        return

    self.stop = ->
        if not fRunning then return
        server.close()
        fRunning = false
        return

    self.handler = (aHandler) ->

        handler = (req, res) ->
            body = ''
            req.setEncoding('utf8')
            req.on 'data', (chunk) ->
                body += chunk
                return

            req.on 'end', ->
                if body
                    try
                        req.body = JSON.parse(body)
                    catch err
                        req.body = err
                else req.body = null
                aHandler(req, res)
                return
            return

        server.removeAllListeners('request')
        server.on('request', handler)
        return

    return self
