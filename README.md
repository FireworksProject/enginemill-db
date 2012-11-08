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
Once you have a database connection, you can start using the API.

### get()

### set()

### remove()

### query()


Copyright and License
---------------------
Copyright: (c) 2012 by The Fireworks Project (http://www.fireworksproject.com)

Unless otherwise indicated, all source code is licensed under the MIT license. See MIT-LICENSE for details.
