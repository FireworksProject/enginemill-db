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
        @expectCount(10)
        opts = _.clone(OPTS)
        opts.hostname = 'example.com'
        opts.secure = true
        opts.creds = {username: 'uname', password: 'secret'}
        delete opts.port

        mockDB = {}

        t = @

        CDB.srv = (urlString) ->
            url = URL.parse(urlString)
            t.equal(url.protocol, 'https:', 'url protocol')
            t.equal(url.hostname, 'example.com', 'url hostname')
            t.equal(url.port, '443', 'url port')
            t.equal(url.auth, 'uname:secret', 'url auth')
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


    it 'should raise an exception if aOpts.creds is provided but invalid', T (done) ->
        opts = _.clone(OPTS)
        opts.creds = {foo: 'bar'}

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect(aOpts) aOpts.creds.username must be a String.', 'message')

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


    it 'should reject if the database does not exist', T (done) ->
        @expectCount(2)
        t = @

        handler = (req, res) ->
            res.statusCode = 404
            res.end(JSON.stringify({error: 'not_found', reason: 'no_db_file'}))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.assert(false, 'success handler should not execute')
            return done()

        failure = (err) ->
            t.equal(err.code, 'ENODB', 'Error.code')
            t.equal(err.message, "enginemill-db::api.get(aId) database 'test_db' does not exist.", 'Error.message')
            return done()

        EDB.connect(OPTS).get('foo').then(success, failure).done()
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


    it 'should create a new document', T (done) ->
        @expectCount(7)
        t = @
        document = {field_1: 1}

        handler = (req, res) ->
            t.equal(req.body._id, undefined, 'POST _id')
            t.equal(req.body.field_1, 1, 'POST field_1')
            t.equal(req.method, 'POST', 'http method')
            t.equal(req.url, '/test_db', 'http url')
            res.statusCode = 201
            rv =
                id: '123abc'
                rev: '1234567'
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.equal(doc._id, '123abc', '._id')
            t.equal(doc._rev, undefined, '._rev')
            t.equal(doc.field_1, 1, 'field_1')
            return done()

        EDB.connect(OPTS).set(document).then(success, done).done()
        return


    it 'should handle a document conflict', T (done) ->
        @expectCount(2)
        t = @
        document = {_id: '123abc', field_1: 1}

        handler = (req, res) ->
            res.statusCode = 409
            err = {error: 'conflict', reason: 'Document update conflict.'}
            res.end(JSON.stringify(err))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.assert(false, 'success handler should not be called')
            return done()

        failure = (err) ->
            t.equal(err.code, 'CONFLICT', 'error.code')
            t.equal(err.message, 'Document conflict rejection id: 123abc', 'err.message')
            return done()

        EDB.connect(OPTS).set(document).then(success, failure).done()
        return


    it 'should use _rev from previously set() document', T (done) ->
        @expectCount(4)
        t = @
        docid = '902345asdflknsdfij'
        rev = '1234567'
        document = {field: 'foo'}

        handler = (req, res) ->
            if req.method is 'POST'
                res.statusCode = 201
                rv = {id: docid, rev: rev}
                return res.end(JSON.stringify(rv))

            # Test the revision identifier
            doc = req.body
            t.equal(doc._rev, rev, 'set _rev')

            res.statusCode = 201
            rv = {id: document._id, rev: '89'}
            return res.end(JSON.stringify(rv))

        gServer.handler(handler)

        db = EDB.connect(OPTS)

        onFirstSet = (doc) ->
            t.equal(doc._id, docid, '_id')
            return db.set(doc).then(onSecondSet)

        onSecondSet = (doc) ->
            t.equal(doc._id, docid, '_id')
            t.equal(doc._rev, undefined, '_rev')
            return done()

        db.set(document).then(onFirstSet, done).done()
        return


    it 'should use _rev from previous get()', T (done) ->
        @expectCount(3)
        t = @
        docid = '902345asdflknsdfij'
        document =
            _id: docid
            _rev: '123-abc'

        handler = (req, res) ->
            if req.method is 'GET'
                res.statusCode = 200
                return res.end(JSON.stringify(document))

            # Test the revision identifier
            doc = req.body
            t.equal(doc._rev, document._rev, 'set _rev')

            res.statusCode = 201
            rv =
                id: document._id
                rev: '456-abc'
            return res.end(JSON.stringify(rv))

        gServer.handler(handler)

        db = EDB.connect(OPTS)

        onGet = (doc) ->
            return db.set(doc).then(onSet)

        onSet = (doc) ->
            t.equal(doc._id, document._id, '_id')
            t.equal(doc._rev, undefined, '_rev')
            return done()

        db.get(docid).then(onGet, done).done()
        return


    it 'should use _rev from previous query()', T (done) ->
        @expectCount(3)
        t = @
        document =
            _id: '902345asdflknsdfij'
            _rev: '123-abc'
            email: 'me@example.com'

        doc2 =
            _id: '123'
            _rev: 'abc'
            email: 'you@example.com'

        handler = (req, res) ->
            if req.method is 'GET'
                res.statusCode = 200
                results = {}
                results.rows = [
                    {id: document._id, key: document.email, value: document}
                    {id: doc2._id, key: doc2.email, value: doc2}
                ]
                return res.end(JSON.stringify(results))

            # Test the revision identifier
            doc = req.body
            t.equal(doc._rev, document._rev, 'set _rev')

            res.statusCode = 201
            rv =
                id: document._id
                rev: '456-abc'
            return res.end(JSON.stringify(rv))

        gServer.handler(handler)

        db = EDB.connect(OPTS)

        onGet = (docs) ->
            doc = _.clone(docs[0])
            return db.set(doc).then(onSet)

        onSet = (doc) ->
            t.equal(doc._id, document._id, '_id')
            t.equal(doc._rev, undefined, '_rev')
            return done()

        db.query('my_docs').then(onGet, done).done()
        return


    it 'should reject if the database does not exist', T (done) ->
        @expectCount(2)
        t = @

        handler = (req, res) ->
            res.statusCode = 404
            res.end(JSON.stringify({error: 'not_found', reason: 'no_db_file'}))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.assert(false, 'success handler should not execute')
            return done()

        failure = (err) ->
            t.equal(err.code, 'ENODB', 'Error.code')
            t.equal(err.message, "enginemill-db::api.set(aId) database 'test_db' does not exist.", 'Error.message')
            return done()

        doc = {_id: 'foobar'}
        EDB.connect(OPTS).set(doc).then(success, failure).done()
        return

    return


describe 'api.remove(aId)', ->
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


    it 'should delete a document and return true', T (done) ->
        @expectCount(4)
        t = @
        docid = 'lkj3245098sdf'
        docrev = '123-456'

        handler = (req, res) ->
            if req.method is 'GET'
                res.statusCode = 200
                doc = {_id: docid, _rev: docrev}
                return res.end(JSON.stringify(doc))

            t.equal(req.method, 'DELETE', 'request method')
            t.equal(req.url, "/test_db/#{docid}", 'request url')
            t.equal(req.headers['if-match'], docrev, 'if-match header')

            res.statusCode = 200
            rv = {ok: 'true', id: docid, rev: '1234567'}
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (res) ->
            t.strictEqual(res, true, 'response')
            return done()

        test = (doc) ->
            return db.remove(doc._id).then(success, done)

        db = EDB.connect(OPTS)
        db.get(docid).then(test).done()
        return


    it 'should throw an error if the document has not been fetched', T (done) ->
        @expectCount(2)
        t = @
        docid = 'lkj3245098sdf'

        handler = (req, res) ->
            res.statusCode = 200
            doc = {_id: 'someotherdoc', _rev: '123456'}
            return res.end(JSON.stringify(doc))

        gServer.handler(handler)

        test = ->
            try
                db.remove(docid)
                t.assert(false, 'should not execute')
            catch err
                t.equal(err.code, 'INVPARAM', 'Error.code')
                t.equal(err.message, "enginemill-db::A document must be fetched before it can be removed with api.remove(aId).", 'Error.message')

            return done()

        db = EDB.connect(OPTS)
        db.get('someotherdoc').then(test).done()
        return


    it 'should return false if the document was not found', T (done) ->
        @expectCount(1)
        t = @
        docid = 'lkj3245098sdf'
        docrev = '123-456'

        handler = (req, res) ->
            if req.method is 'GET'
                res.statusCode = 200
                doc = {_id: docid, _rev: docrev}
                return res.end(JSON.stringify(doc))

            res.statusCode = 404
            rv = {error: 'not_found', reason: 'deleted'}
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (res) ->
            t.strictEqual(res, false, 'response')
            return done()

        test = (doc) ->
            return db.remove(doc._id).then(success, done)

        db = EDB.connect(OPTS)
        db.get(docid).then(test).done()
        return


    # SKIP: the .remove() method does not need to reject if the database does
    # not exist, since the document in question must be fetched first.


    it 'should reject with an error if there is a conflict', T (done) ->
        @expectCount(2)
        t = @
        docid = 'lkj3245098sdf'
        docrev = '123-456'

        handler = (req, res) ->
            if req.method is 'GET'
                res.statusCode = 200
                doc = {_id: docid, _rev: docrev}
                return res.end(JSON.stringify(doc))

            res.statusCode = 409
            rv = {error: 'conflict', reason: 'Document update conflict.'}
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (res) ->
            t.assert(false, 'success should not execute')
            return done()

        failure = (err) ->
            t.equal(err.code, 'CONFLICT', 'Error.code')
            t.equal(err.message, "Document conflict rejection id: #{docid}", 'Error.message')
            return done()

        test = (doc) ->
            return db.remove(doc._id).then(success, failure)

        db = EDB.connect(OPTS)
        db.get(docid).then(test).done()
        return

    return


describe 'api.query(aIndex, aQuery)', ->
    gServer = null

    before (done) ->
        gServer = createCouchDBServer()
        gServer.start(done)
        return

    after (done) ->
        gServer.stop()
        return done()



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


    it 'should return an Array of results', T (done) ->
        @expectCount(5)
        t = @

        doc1 =
            _id: 'doc1'
            _rev: '123'
            email: 'me@example.com'
        doc2 =
            _id: 'doc2'
            _rev: '456'
            email: 'you@example.com'

        handler = (req, res) ->
            t.equal(req.url, '/test_db/_design/application/_view/people_by_email', 'request url')

            res.statusCode = 200
            results = {}
            results.rows = [
                {id: doc1._id, key: doc1.email, value: doc1}
                {id: doc2._id, key: doc2.email, value: doc2}
            ]
            res.end(JSON.stringify(results))
            return

        gServer.handler(handler)

        success = (rows) ->
            row1 = rows[0]
            row2 = rows[1]
            t.equal(row1._id, doc1._id, 'doc1._id')
            t.equal(row1._rev, undefined, 'doc1._rev')
            t.equal(row2._id, doc2._id, 'doc2._id')
            t.equal(row2._rev, undefined, 'doc2._rev')
            return done()

        EDB.connect(OPTS).query('people_by_email').then(success, done).done()
        return


    it 'should pass query parameters', T (done) ->
        @expectCount(4)
        t = @

        handler = (req, res) ->
            url = URL.parse(req.url, yes)
            t.equal(url.pathname, '/test_db/_design/application/_view/foo', 'request url')
            query = url.query
            t.equal(query.limit, '10', 'limit')
            t.equal(query.descending, 'true', 'descending')
            t.equal(query.startkey, '["foo",123]', 'startkey')

            res.statusCode = 200
            res.end(JSON.stringify({rows: []}))
            return

        gServer.handler(handler)

        success = (rows) ->
            return done()

        query =
            limit: 10
            descending: true
            startkey: ['foo', 123]

        EDB.connect(OPTS).query('foo', query).then(success, done).done()
        return


    it 'should return an Error rejection if the index cannot be found', T (done) ->
        @expectCount(2)
        t = @

        handler = (req, res) ->
            res.statusCode = 404
            rv = {error: 'not_found', reason: 'missing_named_view'}
            res.end(JSON.stringify(rv))
            return

        gServer.handler(handler)

        success = (rows) ->
            t.assert(false, 'success handler should not execute')
            return done()

        failure = (err) ->
            t.equal(err.code, 'NOTFOUND', 'Error.code')
            t.equal(err.message, "Index 'foo' not found.", 'Error.message')
            return done()

        EDB.connect(OPTS).query('foo').then(success, failure).done()
        return


    it 'should reject if the database does not exist', T (done) ->
        @expectCount(2)
        t = @

        handler = (req, res) ->
            res.statusCode = 404
            res.end(JSON.stringify({error: 'not_found', reason: 'no_db_file'}))
            return

        gServer.handler(handler)

        success = (doc) ->
            t.assert(false, 'success handler should not execute')
            return done()

        failure = (err) ->
            t.equal(err.code, 'ENODB', 'Error.code')
            t.equal(err.message, "enginemill-db::api.query(aId) database 'test_db' does not exist.", 'Error.message')
            return done()

        EDB.connect(OPTS).query('foo').then(success, failure).done()
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

        EDB.connect(OPTS).query('foo').then(success, failure).done()
        return


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
