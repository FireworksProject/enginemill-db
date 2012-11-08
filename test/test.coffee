URL = require 'url'

TOOLS = require 'test-tools'
T = TOOLS.test
_ = TOOLS.underscore

EDB = require '../dist/enginemill-db'

CDB = require '../dist/node_modules/couchdb-api/'

describe 'connect()', ->
    COUCHDB_srv = CDB.srv

    gOpts =
        hostname: 'localhost'
        port: 5984
        database: 'test_db'
        secure: false

    after = (done) ->
        CDB.srv = COUCHDB_srv
        return done()


    it 'should create a database connection', T (done) ->
        @expectCount(9)
        opts = _.clone(gOpts)
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
            server = {database: database}
            return server

        database = (name) ->
            t.equal(name, 'test_db', 'database name')
            return mockDB

        db = EDB.connect(opts)
        @assert(Object.isFrozen(db), 'API Object is frozen')
        @assert(_.isFunction(db.get), 'db.get')
        @assert(_.isFunction(db.set), 'db.set')
        @assert(_.isFunction(db.remove), 'db.remove')
        @assert(_.isFunction(db.query), 'db.query')
        return done()


    it 'should raise an exception if aOpts.hostname is missing', T (done) ->
        opts = _.clone(gOpts)
        delete opts.hostname

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect() aOpts.hostname is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.hostname isnt a String', T (done) ->
        opts = _.clone(gOpts)
        opts.hostname = 80

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect() aOpts.hostname must be a String.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.port is truthy but not a number', T (done) ->
        opts = _.clone(gOpts)
        opts.port = '5984'

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect() aOpts.port must be a Number.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.database is missing', T (done) ->
        opts = _.clone(gOpts)
        opts.database = ''

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect() aOpts.database is required.', 'message')

        @expectCount(2)
        return done()


    it 'should raise an exception if aOpts.database isnt a String', T (done) ->
        opts = _.clone(gOpts)
        opts.database = false

        try
            EDB.connect(opts)
        catch err
            @equal(err.code, 'INVPARAM', 'code')
            @equal(err.message, 'enginemill-db::connect() aOpts.database must be a String.', 'message')

        @expectCount(2)
        return done()

    return
