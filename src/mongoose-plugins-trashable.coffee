debug    = require('debug')('mongoose-plugins-trashable:main')
mongoose = require('mongoose')
Model    = mongoose.Model
Query    = mongoose.Query
Schema   = mongoose.Schema

module.exports = (schema, options) ->

    schema.add
        trashedAt :
            type     : Date
            default  : null

        trashedBy :
            type     : Schema.Types.ObjectId
            default  : null

    # Static methods

    schema.statics.count = ->
        Model.count.apply(this, arguments)
        .where('trashedAt').equals(null)

    schema.statics.countTrashed = ->
        Model.count.apply(this, arguments)
        .where('trashedAt').ne(null)

    schema.statics.countWithTrashed = ->
        Model.count.apply(this, arguments)

    schema.statics.find = ->
        Model.find.apply(this, arguments)
        .where('trashedAt').equals(null)

    schema.statics.findTrashed = ->
        Model.find.apply(this, arguments)
        .where('trashedAt').ne(null)

    schema.statics.findWithTrashed = ->
        Model.find.apply(this, arguments)

    schema.statics.findOne = ->
        Model.findOne.apply(this, arguments)
        .where('trashedAt').equals(null)

    schema.statics.findOneTrashed = ->
        Model.findOne.apply(this, arguments)
        .where('trashedAt').ne(null)

    schema.statics.findOneWithTrashed = ->
        Model.findOne.apply(this, arguments)

    schema.statics.findById = (id, fields, options, callback) ->
        this.findOne({ _id: id }, fields, options, callback)

    schema.statics.findTrashedById = (id, fields, options, callback) ->
        this.findOneTrashed({ _id: id }, fields, options, callback)

    schema.statics.findWithTrashedById = (id, fields, options, callback) ->
        this.findOneWithTrashed({ _id: id }, fields, options, callback)

    schema.statics.trash = (conditions, callback) ->
        this.where('trashedAt').equals(null)
        .update(conditions, { trashedAt: new Date() }, { multi: true }, callback)

    schema.statics.restore = (conditions, callback) ->
        this.where('trashedAt').ne(null)
        .update(conditions, { trashedAt: null, trashedBy: null }, { multi: true }, callback)

    # Instance methods

    schema.methods.trash = (callback) ->
        conditions =
            _id       : this.id
            trashedAt : null

        updates =
            trashedAt : new Date()

        this.constructor.findOneAndUpdate(conditions, updates, callback)

    schema.methods.restore = (callback) ->
        conditions =
            _id       : this.id
            trashedAt : { $ne: null }

        updates =
            trashedAt : null
            trashedBy : null

        this.constructor.findOneAndUpdate(conditions, updates, callback)

# Extends Mongoose.Query
Query.prototype.by = (instance, callback) ->
    [instance, callback] = [null, instance] if typeof instance is 'function'

    doc = this._update
    doc.trashedBy = instance.id if instance?
    options     = undefined
    castedQuery = undefined
    castedDoc   = undefined

    try
        castedQuery = this.cast(this.model)
        castedDoc   = this._castUpdate(doc, options?.overwrite)
    catch err
        debug(err)
        if callback?
            callback(err)
            return this
        else
            throw err

    if castedQuery._id
        Query.base.findOneAndUpdate.call(this, castedQuery, castedDoc, options, callback)
    else
        Query.base.update.call(this, castedQuery, castedDoc, options, callback)
