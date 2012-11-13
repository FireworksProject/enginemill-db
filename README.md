Enginemill DB
=============
Enginemill DB is a database abstraction layer for Node.js applications. We use
it internally at the
[Fireworks Project](http://www.fireworksproject.com)
as a plugin to our Enginemill web development framework.

The abstraction created by Enginemill DB treats the underlying database as a
collection of JSON documents. It supports get, set, remove, and query methods
to operate on the database.  However, it does not provide a way to create the
indexes needed to support the query method, so the indexes must already be
created through outside channels.

Currently CouchDB is the only supported underlying database engine.

## Installation
Enginemill DB is designed to be installed by including it in the package.json
dependencies list for your web project.  Follow the
[npm documentation for package.json](https://npmjs.org/doc/json.html)
if you don't already know how to do that.

Once you have it listed in the package.json for your project, just run

    npm install

from the root of your project.

## Usage
Load Enginemill DB into a Node.js module by requiring it.

```JavaScript
    var EDB = require('enginemill-db');
```

Create a database API by creating a connection. In the case of CouchDB it looks like this:
```JavaScript
    var db = EDB.connect({
      hostname: 'localhost'
    , port: 5984
    , secure: false
    , database: 'my_database'
    });
```

The connect() docs:

### ::connect
_::connect(aOpts)_ Create a database connection.

* aOpts - An options Object hash
* aOpts.hostname - The String hostname of the CouchDB server.
* aOpts.port - The port Number to use (default: 5984 if aOpts.secure is
               false, and 443 if it is true).
* aOpts.database - The String database name to use.
* aOpts.secure - A boolean flag to indicate the connection should be
            secure (default: false).
* aOpts.creds - An credentials Object hash.
* aOpts.creds.username - The username String.
* aOpts.creds.password - The password String.

_Throws_ Error objects with code 'INVPARAM' if any invalid parameters are
passed or required parameters are missing.

_Returns_ a Database API instance.

## Database API
Once you have a database connection, you can start using the API. All function
return a Promise object from the Q module. Use the examples below and the
[Q documentation](https://github.com/kriskowal/q#readme)
to learn how to use Promises to be a master of this asynchronous environment.

### get
_get(aId)_ Fetch a document from the database.

* aId - The id String of the document to get.

_Returns_ a Q::Promise Object which resolves to an Object representation of the
document. If the document does not exist in the database then the promise will
resolve to null.

```JavaScript
function requestHandler(req, res) {
    var postId = req.url.split('/')[1];

    function success(document) {
        if (document) {
            res.statusCode = 200;
            res.end(document.body);
        } else {
            res.statusCode = 404;
            res.end('Not Found');
        }
        return;
    }

    function failure(err) {
        res.statusCode = 500;
        res.end(err.stack);
        return;
    }

    db.get(postId).then(success, failure);
    return;
}
```

### set
_set(aDoc)_ Save a document to the database.

* aDoc - The JavaScript Object representing the document.

_Returns_ a Q::Promise Object which resolves to a *new* Object representation
of the document. The promise will reject if there is a conflict error.

### remove
_remove(aId)_ Delete a document from the database.

* aId - The id String of the document to delete.

If the document has not been fetched with .get() or query() then an Error
with code 'INVPARAM' will be thrown.

_Returns_ a Q::Promise Object which resolves to `true` if the document was
deleted and `false` if it didn't exist in the first place. The promise will
reject if there is a conflict error.

### query
_query(aIndex, aQuery)_ Query an index of documents based on a key range.

* aIndex - The name String of the index to query.
* aQuery - The Object hash of query parameters.
* aQuery.key - The key to use (may be String, Number, Null, or Array).
* aQuery.limit - The max Number of documents to include in the results.
* aQuery.descending - A Boolean flag which can be used to reverse the
                      order of the range scan (default: false).
* aQuery.startkey - The key to begin a range scan on
                    (may be String, Number, Null, or Array).
* aQuery.endkey - The key to end a range scan on
                  (may be String, Number, Null, or Array).

It is assumed that the index has already been created through another
channel.  If it hasn't, then the returned Q::Promise will reject with a
'NOTFOUND' Error.

_Returns_ a Q::Promise Object which resolves to an Array of documents
represented by JavaScript Objects.


Copyright and License
---------------------
Copyright: (c) 2012 by The Fireworks Project (http://www.fireworksproject.com)

Unless otherwise indicated, all source code is licensed under the MIT license. See MIT-LICENSE for details.
