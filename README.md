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
__::connect(aOpts)__ Create a database connection.

* *__aOpts__* - An options Object hash
* *__aOpts.hostname__* - The String hostname of the CouchDB server.
* *__aOpts.port__* - The port Number to use (default: 5984 if aOpts.secure is
               false, and 443 if it is true).
* *__aOpts.database__* - The String database name to use.
* *__aOpts.secure__* - A boolean flag to indicate the connection should be
            secure (default: false).
* *__aOpts.creds__* - An credentials Object hash.
* *__aOpts.creds.username__* - The username String.
* *__aOpts.creds.password__* - The password String.

*__Throws__* Error objects with code 'INVPARAM' if any invalid parameters are
passed or required parameters are missing.

*__Returns__* a Database API instance.

## Database API
Once you have a database connection, you can start using the API. All functions
return a Promise object from the Q module. Use the examples below and the
[Q documentation](https://github.com/kriskowal/q#readme)
to learn how to use Promises to master of the Node.js asynchronous environment.

### get
__get(aId)__ Fetch a document from the database.

* *__aId__* - The id String of the document to get.

*__Returns__* a Q::Promise Object which resolves to an Object representation of the
document. If the document does not exist in the database then the promise will
resolve to null.

```JavaScript
    var docId = 'abc123';

    function success(document) {
        if (document) {
            console.log('got document', document);
        } else {
            console.log('document is not in the DB');
        }
        return;
    }

    function failure(err) {
        console.error('Unexpected Database error:');
        console.error(err.stack);
    }

    db.get(docId).then(success, failure);
```

### set
__set(aDoc)__ Save a document to the database.

* *__aDoc__* - The JavaScript Object representing the document.

*__Returns__* a Q::Promise Object which resolves to a *new* Object representation
of the document. The promise will reject if there is a conflict error.

```JavaScript
function myTransaction() {
    var doc = {
      first_name: 'John'
    , last_name: 'Doe'
    , age: 44
    , _id: 'abc123'
    };

    function success(document) {
        console.log('Saved document.');
    }

    function failure(err) {
        if (err.code === 'CONFLICT') {
            console.log('Document conflict error. Trying again.);
            myTransaction();
        } else {
            console.error('Unexpected Database error:');
            console.error(err.stack);
        }
    }

    return db.set(doc).then(success, failure);
}
```

### remove
__remove(aId)__ Delete a document from the database.

* *__aId__* - The id String of the document to delete.

If the document has not been fetched with .get() or query() then an Error
with code 'INVPARAM' will be thrown.

*__Returns__* a Q::Promise Object which resolves to `true` if the document was
deleted and `false` if it didn't exist in the first place. The promise will
reject if there is a conflict error.

### query
__query(aIndex, aQuery)__ Query an index of documents based on a key range.

* *__aIndex__* - The name String of the index to query.
* *__aQuery__* - The Object hash of query parameters.
* *__aQuery.key__* - The key to use (may be String, Number, Null, or Array).
* *__aQuery.limit__* - The max Number of documents to include in the results.
* *__aQuery.descending__* - A Boolean flag which can be used to reverse the
                      order of the range scan (default: false).
* *__aQuery.startkey__* - The key to begin a range scan on
                    (may be String, Number, Null, or Array).
* *__aQuery.endkey__* - The key to end a range scan on
                  (may be String, Number, Null, or Array).

It is assumed that the index has already been created through another
channel.  If it hasn't, then the returned Q::Promise will reject with a
'NOTFOUND' Error.

*__Returns__* a Q::Promise Object which resolves to an Array of documents
represented by JavaScript Objects.


Copyright and License
---------------------
Copyright: (c) 2012 by The Fireworks Project (http://www.fireworksproject.com)

Unless otherwise indicated, all source code is licensed under the MIT license. See MIT-LICENSE for details.
