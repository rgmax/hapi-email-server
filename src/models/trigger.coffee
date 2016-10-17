_ = require "lodash"
Q = require "q"

module.exports = (server, options) ->

  bucket = options.database

  return class Trigger

    PREFIX: "postoffice"
    POSTFIX: "unsubscribe"

    @subscribe: (trigger_point, emails) ->
      _this = @
      @get_trigger_event(trigger_point)
      .then (trigger_event) ->
        return trigger_event if trigger_event instanceof Error
        trigger_key = _this._trigger_key(trigger_point)
        doc = { subscribers: emails }
        bucket.get(trigger_key)
        .then (d) ->
          if d instanceof Error
            bucket.insert(trigger_key, doc)
          else
            bucket.replace(trigger_key, doc)

    @post: (trigger_point, data, email) ->
      new Error("Not implemented yet!")

    @unsubscribe: (email, trigger_points) ->
      key = @_unsubscribe_key(email)
      doc = { trigger_points: trigger_points }
      bucket.get(key)
      .then (d) ->
        if d instanceof Error
          bucket.insert(key, doc)
        else
          bucket.replace(key, doc)

    @get_trigger_event: (trigger_point) ->
      parts = trigger_point.split(":")
      trigger_event = parts[ parts.length - 1 ]
      trigger_events = _.keys options.trigger_events
      return Q( new Error("Trigger event '#{trigger_event}' is not defined!") ) if trigger_events.indexOf(trigger_event) < 0
      Q trigger_event

    @_trigger_key: (trigger_point) ->
      "#{Trigger::PREFIX}:#{trigger_point}"

    @_unsubscribe_key: (email) ->
      "#{Trigger::PREFIX}:#{email}:#{Trigger::POSTFIX}"