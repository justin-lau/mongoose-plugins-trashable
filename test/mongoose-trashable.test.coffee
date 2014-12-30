chai              = require('chai')
chaiAsPromised    = require('chai-as-promised')
debug             = require('debug')('mongoose-plugins-trashable:test')
mongoose          = require('mongoose')
Q                 = require('q')
Schema            = mongoose.Schema
Query             = mongoose.Query
should            = chai.should()
mongooseTrashable = require('../')

chai.use(chaiAsPromised)

Trashable = null
User      = null

before ->
    mongoose.connect('mongodb://localhost/test-mongoose-plugins-trashable')
    mongoose.connection.on 'error', (err) ->
        debug("MongoDB error: #{ err.message }")
        debug("Make sure MongoDB is up and running.")

    TrashableSchema = new Schema(index: Number, value: Number)
    TrashableSchema.plugin(mongooseTrashable)
    Trashable = mongoose.model('Trashable', TrashableSchema)

    UserSchema = new Schema({})
    User = mongoose.model('User', UserSchema)

after ->
    mongoose.connection.db.dropDatabase()


describe 'Trashable Instances', ->

    it 'should have `trash()` method', ->
        Trashable.create({}).should.eventually.respondTo('trash')

    it 'should have `restore()` method', ->
        Trashable.create({}).should.eventually.respondTo('restore')

describe 'mongoose.Query', ->

    it 'should have `by()` method', ->
        Query.should.respondTo('by')


describe 'Instance Methods', ->

    beforeEach -> Q.all [
        Trashable.remove({}).exec()
        User.remove({}).exec()
    ]

    describe 'trash()', ->

        describe '(with callbacks)', ->

            it 'should mark an instance as trashed', (done) ->

                Trashable.create({}).then (trashable) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null

                    trashable.trash (err, trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy').that.is.null
                        done()
                    return
                return

        describe '(with promises)', ->

            it 'should mark an instance as trashed', ->

                Trashable.create({}).then (trashable) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null

                    trashable.trash().exec().then (trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy').that.is.null

    describe 'by()', ->

        describe '(with callbacks)', ->

            it 'should do nothing if no model instance is passed in', (done) ->

                Trashable.create({}).then (trashable) ->
                    trashable.trash().by (err, trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy').that.is.null
                        done()
                    return
                return

            it 'should record the model that get passed in', (done) ->

                Q.all [
                    Trashable.create({})
                    User.create({})
                ]
                .spread (trashable, user) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null

                    trashable.trash().by user, (err, trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy')

                        trashable.trashedBy.equals(user.id).should.be.true

                        done()
                    return
                return

        describe '(with promises)', ->

            it 'should do nothing if no model instance is passed in', ->

                Trashable.create({}).then (trashable) ->
                    trashable.trash().by().exec().onFulfill (trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy').that.is.null

            it 'should record the model that get passed in', ->

                Q.all [
                    Trashable.create({})
                    User.create({})
                ]
                .spread (trashable, user) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null

                    trashable.trash().by(user).exec().onFulfill (trashable) ->
                        trashable.should.have.property('trashedAt').that.is.a('Date')
                        trashable.should.have.property('trashedBy')

                        trashable.trashedBy.equals(user.id).should.be.true

    describe 'restore()', ->

        describe '(with callbacks)', ->

            it 'should restore a previously trashed model', (done) ->

                Q.all [
                    Trashable.create({})
                    Trashable.create({})
                    User.create({})
                ]
                .spread (trashable, trashableWithUser, user) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null
                    trashableWithUser.should.have.property('trashedAt').that.is.null
                    trashableWithUser.should.have.property('trashedBy').that.is.null

                    trashable.trash (err, trashable) ->
                        trashable.restore (err, trashable) ->
                            trashable.should.have.property('trashedAt').that.is.null
                            trashable.should.have.property('trashedBy').that.is.null

                            trashableWithUser.trash().by user, (err, trashableWithUser) ->
                                trashableWithUser.restore (err, trashableWithUser) ->
                                    trashableWithUser.should.have.property('trashedAt').that.is.null
                                    trashableWithUser.should.have.property('trashedBy').that.is.null

                                    done()
                    return
                return

        describe '(with promises)', ->

            it 'should restore a previously trashed model', ->

                Q.all [
                    Trashable.create({})
                    Trashable.create({})
                    User.create({})
                ]
                .spread (trashable, trashableWithUser, user) ->
                    trashable.should.have.property('trashedAt').that.is.null
                    trashable.should.have.property('trashedBy').that.is.null
                    trashableWithUser.should.have.property('trashedAt').that.is.null
                    trashableWithUser.should.have.property('trashedBy').that.is.null

                    Q.all [
                        trashable.trash().exec().onFulfill ->
                            trashable.restore().exec().onFulfill (trashable) ->
                                trashable.should.have.property('trashedAt').that.is.null
                                trashable.should.have.property('trashedBy').that.is.null
                        trashableWithUser.trash().by(user).exec().onFulfill (trashable) ->
                            trashableWithUser.restore().exec().onFulfill ->
                                trashableWithUser.should.have.property('trashedAt').that.is.null
                                trashableWithUser.should.have.property('trashedBy').that.is.null
                    ]

describe 'Static Methods', ->

    user = null;

    beforeEach ->
        Q.all [
            Trashable.remove({}).exec()
            User.create({})
        ]
        .spread (removedCount, newUser) ->
            user = newUser

            Q.all [
                Trashable.create({ index: 0, value: 0 })
                Trashable.create({ index: 1, value: 0 }).then (trashable) -> trashable.trash().exec()
                Trashable.create({ index: 2, value: 0 }).then (trashable) -> trashable.trash().by(user).exec()
                Trashable.create({ index: 3, value: 1 })
                Trashable.create({ index: 4, value: 1 }).then (trashable) -> trashable.trash().exec()
                Trashable.create({ index: 5, value: 1 }).then (trashable) -> trashable.trash().by(user).exec()
                Trashable.create({ index: 6, value: 2 })
                Trashable.create({ index: 7, value: 3 }).then (trashable) -> trashable.trash().exec()
            ]

    describe 'count()', ->

        it 'should count non-trashed instances only', -> Q.all [
            Trashable.count({ value: 0 }).exec().should.eventually.equal(1)
            Trashable.count({ value: 1 }).exec().should.eventually.equal(1)
            Trashable.count({ value: 2 }).exec().should.eventually.equal(1)
            Trashable.count({ value: 3 }).exec().should.eventually.equal(0)
        ]

    describe 'countTrashed()', ->

        it 'should count trashed instances only', -> Q.all [
            Trashable.countTrashed().exec().should.eventually.equal(5)
            Trashable.countTrashed({ value: 0 }).exec().should.eventually.equal(2)
            Trashable.countTrashed({ value: 1 }).exec().should.eventually.equal(2)
            Trashable.countTrashed({ value: 2 }).exec().should.eventually.equal(0)
            Trashable.countTrashed({ value: 3 }).exec().should.eventually.equal(1)
        ]

    describe 'countWithTrashed()', ->

        it 'should count all instances (trashed/non-trashed)', -> Q.all [
            Trashable.countWithTrashed().exec().should.eventually.equal(8)
            Trashable.countWithTrashed({ value: 0 }).exec().should.eventually.equal(3)
            Trashable.countWithTrashed({ value: 1 }).exec().should.eventually.equal(3)
            Trashable.countWithTrashed({ value: 2 }).exec().should.eventually.equal(1)
            Trashable.countWithTrashed({ value: 3 }).exec().should.eventually.equal(1)
        ]

    describe 'find()', ->

        it 'should find non-trashed instances only', -> Q.all [
            Trashable.find().exec().should.eventually.have.lengthOf(3)
            Trashable.find({ value: 0 }).exec().should.eventually.have.lengthOf(1)
            Trashable.find({ value: 1 }).exec().should.eventually.have.lengthOf(1)
            Trashable.find({ value: 2 }).exec().should.eventually.have.lengthOf(1)
            Trashable.find({ value: 3 }).exec().should.eventually.have.lengthOf(0)
        ]

    describe 'findTrashed()', ->

        it 'should find trashed instances only', -> Q.all [
            Trashable.findTrashed().exec().should.eventually.have.lengthOf(5)
            Trashable.findTrashed({ value: 0 }).exec().should.eventually.have.lengthOf(2)
            Trashable.findTrashed({ value: 1 }).exec().should.eventually.have.lengthOf(2)
            Trashable.findTrashed({ value: 2 }).exec().should.eventually.have.lengthOf(0)
            Trashable.findTrashed({ value: 3 }).exec().should.eventually.have.lengthOf(1)
        ]

    describe 'findWithTrashed()', ->

        it 'should work like the original `find()`', -> Q.all [
            Trashable.findWithTrashed().exec().should.eventually.have.lengthOf(8)
            Trashable.findWithTrashed({ value: 0 }).exec().should.eventually.have.lengthOf(3)
            Trashable.findWithTrashed({ value: 1 }).exec().should.eventually.have.lengthOf(3)
            Trashable.findWithTrashed({ value: 2 }).exec().should.eventually.have.lengthOf(1)
            Trashable.findWithTrashed({ value: 3 }).exec().should.eventually.have.lengthOf(1)
        ]

    describe 'findOne()', ->

        it 'should find non-trashed instances only', -> Q.all [
            Trashable.findOne().sort('_id').exec().should.eventually.have.property('index').that.equals(0)
            Trashable.findOne(value: 0).sort('_id').exec().should.eventually.have.property('index').that.equals(0)
            Trashable.findOne(value: 1).sort('_id').exec().should.eventually.have.property('index').that.equals(3)
            Trashable.findOne(value: 2).sort('_id').exec().should.eventually.have.property('index').that.equals(6)
            Trashable.findOne(value: 3).sort('_id').exec().should.eventually.be.null
        ]

    describe 'findOneTrashed()', ->

        it 'should find trashed instances only', -> Q.all [
            Trashable.findOneTrashed().sort('_id').exec().should.eventually.have.property('index').that.equals(1)
            Trashable.findOneTrashed(value: 0).sort('_id').exec().should.eventually.have.property('index').that.equals(1)
            Trashable.findOneTrashed(value: 1).sort('_id').exec().should.eventually.have.property('index').that.equals(4)
            Trashable.findOneTrashed(value: 2).sort('_id').exec().should.eventually.be.null
            Trashable.findOneTrashed(value: 3).sort('_id').exec().should.eventually.have.property('index').that.equals(7)
        ]

    describe 'findOneWithTrashed()', ->

        it 'should work like the original `findOne()`', -> Q.all [
            Trashable.findOneWithTrashed().sort('_id').exec().should.eventually.have.property('index').that.equals(0)
            Trashable.findOneWithTrashed(value: 0).sort('_id').exec().should.eventually.have.property('index').that.equals(0)
            Trashable.findOneWithTrashed(value: 1).sort('_id').exec().should.eventually.have.property('index').that.equals(3)
            Trashable.findOneWithTrashed(value: 2).sort('_id').exec().should.eventually.have.property('index').that.equals(6)
            Trashable.findOneWithTrashed(value: 3).sort('_id').exec().should.eventually.have.property('index').that.equals(7)
        ]

    describe 'findById()', ->

        it 'should find non-trashed instances only', ->
            Trashable.findWithTrashed().sort('_id').exec()
            .then (trashables) ->
                ids = []
                ids.push trashable.id for trashable in trashables
                return ids
            .then (ids) ->
                Q.all [
                    Trashable.findById(ids[0]).exec().should.eventually.have.property('index').that.equals(0)
                    Trashable.findById(ids[1]).exec().should.eventually.be.null
                    Trashable.findById(ids[2]).exec().should.eventually.be.null
                    Trashable.findById(ids[3]).exec().should.eventually.have.property('index').that.equals(3)
                    Trashable.findById(ids[4]).exec().should.eventually.be.null
                    Trashable.findById(ids[5]).exec().should.eventually.be.null
                    Trashable.findById(ids[6]).exec().should.eventually.have.property('index').that.equals(6)
                    Trashable.findById(ids[7]).exec().should.eventually.be.null
                ]

    describe 'findTrashedById()', ->

        it 'should find trashed instances only', ->
            Trashable.findWithTrashed().sort('_id').exec()
            .then (trashables) ->
                ids = []
                ids.push trashable.id for trashable in trashables
                return ids
            .then (ids) ->
                Q.all [
                    Trashable.findTrashedById(ids[0]).exec().should.eventually.be.null
                    Trashable.findTrashedById(ids[1]).exec().should.eventually.have.property('index').that.equals(1)
                    Trashable.findTrashedById(ids[2]).exec().should.eventually.have.property('index').that.equals(2)
                    Trashable.findTrashedById(ids[3]).exec().should.eventually.be.null
                    Trashable.findTrashedById(ids[4]).exec().should.eventually.have.property('index').that.equals(4)
                    Trashable.findTrashedById(ids[5]).exec().should.eventually.have.property('index').that.equals(5)
                    Trashable.findTrashedById(ids[6]).exec().should.eventually.be.null
                    Trashable.findTrashedById(ids[7]).exec().should.eventually.have.property('index').that.equals(7)
                ]

    describe 'findWithTrashedById()', ->

        it 'should work like the original `findById()`', ->
            Trashable.findWithTrashed().sort('_id').exec()
            .then (trashables) ->
                ids = []
                ids.push trashable.id for trashable in trashables
                return ids
            .then (ids) ->
                Q.all [
                    Trashable.findWithTrashedById(ids[0]).exec().should.eventually.have.property('index').that.equals(0)
                    Trashable.findWithTrashedById(ids[1]).exec().should.eventually.have.property('index').that.equals(1)
                    Trashable.findWithTrashedById(ids[2]).exec().should.eventually.have.property('index').that.equals(2)
                    Trashable.findWithTrashedById(ids[3]).exec().should.eventually.have.property('index').that.equals(3)
                    Trashable.findWithTrashedById(ids[4]).exec().should.eventually.have.property('index').that.equals(4)
                    Trashable.findWithTrashedById(ids[5]).exec().should.eventually.have.property('index').that.equals(5)
                    Trashable.findWithTrashedById(ids[6]).exec().should.eventually.have.property('index').that.equals(6)
                    Trashable.findWithTrashedById(ids[7]).exec().should.eventually.have.property('index').that.equals(7)
                ]

    describe 'trash()', ->

        describe '(with callbacks)', ->

            it 'should trash all instances matching the conditions', (done) ->

                Trashable.trash { index: { $lte: 3 } }, (err, numberAffected, rawResponse) ->
                    numberAffected.should.equal(2)

                    Trashable.find().exec()
                    .then (trashables) ->
                        Q.all [
                            trashables.should.have.lengthOf(1)
                            Trashable.findOneTrashed({ index: 0 }).exec().should.eventually.have.property('trashedBy').that.is.null
                            Trashable.findOneTrashed({ index: 3 }).exec().should.eventually.have.property('trashedBy').that.is.null
                        ]
                        .then -> done()
                        .done()
                    .end()


        describe '(with promises)', ->

            it 'should trash all instances matching the conditions', ->

                Trashable.trash({ index: { $lte: 3 } }).exec().then (numberAffected, rawResponse) ->
                    numberAffected.should.equal(2)

                    Q.all [
                        Trashable.find().exec().should.eventually.have.lengthOf(1)
                        Trashable.findOneTrashed({ index: 0 }).exec().should.eventually.have.property('trashedBy').that.is.null
                        Trashable.findOneTrashed({ index: 3 }).exec().should.eventually.have.property('trashedBy').that.is.null
                    ]

    describe 'trash().by()', ->

        describe '(with callbacks)', ->

            it 'should trash all instances matching the conditions and records the User responsible', (done) ->

                Trashable.trash(index: { $lte: 3 }).by (user), (err, numberAffected, rawResponse) ->
                    numberAffected.should.equal(2)

                    Trashable.find().exec()
                    .then (trashables) ->
                        Q.all [
                            trashables.should.have.lengthOf(1)
                            Trashable.findOneTrashed({ index: 0 }).exec().then (trashable) -> trashable.trashedBy.equals(user.id).should.be.true
                            Trashable.findOneTrashed({ index: 3 }).exec().then (trashable) -> trashable.trashedBy.equals(user.id).should.be.true
                        ]
                        .then -> done()
                        .done()
                    .end()


        describe '(with promises)', ->

            it 'should trash all instances matching the conditions and records the User responsible', ->

                Trashable.trash(index: { $lte: 3 }).by(user).exec().then (numberAffected, rawResponse) ->
                    numberAffected.should.equal(2)

                    Q.all [
                        Trashable.find().exec().should.eventually.have.lengthOf(1)
                        Trashable.findOneTrashed({ index: 0 }).exec().then (trashable) -> trashable.trashedBy.equals(user.id).should.be.true
                        Trashable.findOneTrashed({ index: 3 }).exec().then (trashable) -> trashable.trashedBy.equals(user.id).should.be.true
                    ]

    describe 'restore()', ->

        describe '(with callbacks)', ->

            it 'should restore all instances matching the conditions', (done) ->

                Trashable.restore { index: { $lte: 4 } }, (err, numberAffected, rawResponse) ->
                    numberAffected.should.equal(3)

                    Trashable.find().exec()
                    .then (trashables) ->
                        Q.all [
                            trashables.should.have.lengthOf(6)
                            Trashable.findOne({ index: 1 }).exec().should.eventually.have.property('trashedBy').that.is.null
                            Trashable.findOne({ index: 2 }).exec().should.eventually.have.property('trashedBy').that.is.null
                            Trashable.findOne({ index: 4 }).exec().should.eventually.have.property('trashedBy').that.is.null
                        ]
                        .then -> done()
                        .done()
                    .end()


        describe '(with promises)', ->

            it 'should restore all instances matching the conditions', ->

                Trashable.restore({ index: { $lte: 4 } }).exec().then (numberAffected, rawResponse) ->
                    numberAffected.should.equal(3)

                    Q.all [
                        Trashable.find().exec().should.eventually.have.lengthOf(6)
                        Trashable.findOne({ index: 1 }).exec().should.eventually.have.property('trashedBy').that.is.null
                        Trashable.findOne({ index: 2 }).exec().should.eventually.have.property('trashedBy').that.is.null
                        Trashable.findOne({ index: 4 }).exec().should.eventually.have.property('trashedBy').that.is.null
                    ]
