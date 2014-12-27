# mongoose-plugins-trashable

[![Build Status](https://travis-ci.org/justin-lau/mongoose-plugins-trashable.svg?branch=v1.0.0)](https://travis-ci.org/justin-lau/mongoose-plugins-trashable)
![devDependencies Status](https://david-dm.org/justin-lau/mongoose-plugins-trashable/dev-status.svg?style=flat)

This mongoose plugin adds the ability to soft-delete model instances,
optionally records the id of a model (usually a User) responsible for the action.

Also, the `Model.count()`, `Model.find()`, `Model.findOne()`,
`Model.findById()` and other static methods is augmented to show only
non-trashed instances by default. You can still retrieve trashed instances by
using new static methods `Model.findTrashed()`, `Model.findWithTrashed` etc.
Refer to the test cases for their usage.

**Use with Caution**

This plugin internally overriden the model's `count()`, `find()` and many
static methods to retrieve only trashed instances. It also adds a `by()` to
`mongoose.Query` to enable a sweet syntax to record Users responsible for the
delete action.

If you don't feel right about modifying/extending native APIs, please don't use
this plugin.

This plugin is inspired by
[yi's plugin](https://github.com/yi/mongoose-trashable).

## Install

Install the module with:

```bash
npm install mongoose-plugins-trashable
```

## Usage
```javascript
var Schema    = require('mongoose').Schema;
var trashable = require('mongoose-plugins-trashable');
var should    = require('should');

var TrashableSchema = new Schema({});
TrashableSchema.plugin(trachsable);
Trashable = mongoose.model('Trashable', TrashableSchema);

var trashable = new TrashableModel(); // assume async

// the attributes are created with null values
trashable.should.have.property('trashedAt').that.is.null;
trashable.should.have.property('trashedBy').that.is.null;


//
// promise style
//

// trash an object
trashable.trash.exec().then(function(trashable) {
    trashable.should.have.property('trashedAt').that.is.a('Date');
    trashable.should.have.property('trashedBy').that.is.null;
}).done();

// trash an object, and mark the User responsible
var User = mongoose.model('User');
var user = new User({}); // assume async
trashable.trash().by(user).exec().then(function(trashable) {
    trashable.should.have.property('trashedAt').that.is.a('Date');
    trashable.should.have.property('trashedBy');
    trashable.trashedBy.toString().should.equals(user.id);
}).done();

// restore a trashed object
trashable.restore().exec().then(function(trashable) {
    trashable.should.have.property('trashedAt').that.is.null;
    trashable.should.have.property('trashedBy').that.is.null;
}).done();


//
// callback style
//

// trash an object
trashable.trash(function(err, trashable) {
    trashable.should.have.property('trashedAt').that.is.a('Date');
    trashable.should.have.property('trashedBy').that.is.null;
});

// trash an object, and mark the User responsible
var User = mongoose.model('User');
var user = new User({}); // assume async
trashable.trash().by(user, function(err, trashable) {
    trashable.should.have.property('trashedAt').that.is.a('Date');
    trashable.should.have.property('trashedBy');
    trashable.trashedBy.toString().should.equals(user.id);
});

// restore a trashed object
trashable.restore(function(err, trashable) {
    trashable.should.have.property('trashedAt').that.is.null;
    trashable.should.have.property('trashedBy').that.is.null;
});
```

## License

Copyright (c) 2014 Justin Lau <justin@tclau.com>

Licensed under the MIT license.
