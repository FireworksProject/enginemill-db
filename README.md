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

    var EDB = require('enginemill-db');

Create a database API by creating connection. In the case of CouchDB it looks like this:
```JavaScript
    var db = EDB.connect({
      hostname: 'localhost'
    , port: 5984
    , secure: false
    , database: 'my_database'
    });
```

## Database API
Once you have a database connection, you can start using the API. All function
return a Promise object from the Q module. Use the examples below and the
[Q documentation](https://github.com/kriskowal/q#readme)
to learn how to use Promises to be a master of this asynchronous environment.

### get
*get(aId)*
Fetch a document from the database.

* aId - The id String of the document to get.

Returns a Q::Promise Object.

### set
*set(aDoc)*
Save a document to the database.

* aDoc = The JavaScript Object representing the document.

Returns a Q::Promise Object.

### remove
*remove(aId)*
Delete a document from the database.

aId - The id String of the document to delete.

If the document has not been fetched with .get() or query() then an Error
with code 'INVPARAM' will be thrown.

Returns a Q::Promise Object.

### query
*query(aIndex, aQuery)*
Query an index of documents based on a key range.

aIndex - The name String of the index to query.
aQuery - The Object hash of query parameters.
         .key        - The key to use (may be String, Number, Null, or Array).
         .limit      - The max Number of documents to include in the results.
         .descending - A Boolean flag which can be used to reverse the
                       order of the range scan (default: false).
         .startkey   - The key to begin a range scan on
                       (may be String, Number, Null, or Array).
         .endkey     - The key to end a range scan on
                       (may be String, Number, Null, or Array).

It is assumed that the index has already been created through another
channel.  If it hasn't, then the returned Q::Promise will reject with a
'NOTFOUND' Error.

Returns a Q::Promise Object.


Copyright and License
---------------------
Copyright: (c) 2012 by The Fireworks Project (http://www.fireworksproject.com)

Unless otherwise indicated, all source code is licensed under the MIT license. See MIT-LICENSE for details.
