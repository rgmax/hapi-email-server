_ = require "lodash"
Q = require "q"
jade = require 'jade'
Path = require 'path'

module.exports = (server, options) ->

  bucket = options.database
  mailgun = require('mailgun-js') { apiKey: options.mailgun.api_key, domain: options.mailgun.domain }

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
      _this = @
      @get_trigger_event(trigger_point)
      .then (trigger_event) ->
        return trigger_event if trigger_event instanceof Error
        if email?
          _this.render_emails_data(trigger_event, data, [email])
          .then (emails_data) ->
            _this.send(emails_data[0])
        else
          _this.get_subscribers(trigger_point)
          .then (emails) ->
            return emails if emails instanceof Error
            _this.render_emails_data(trigger_event, data, emails)
            .then (emails_data) ->
              promises = []
              _.each emails_data, (email_data) ->
                promises.push _this.send(email_data)
              Q.all(promises)

    @send: (email_data) ->
      deferred = Q.defer()
      if options.mock
        console.log "From: #{email_data.from}"
        console.log "To: #{email_data.to}"
        console.log "Subject: #{email_data.subject}"
        console.log email_data.html
        deferred.resolve(true)
      else
        mailgun.messages().send email_data,
          (error, body) ->
            if error
              deferred.reject new Error error
            else
              deferred.resolve body
      deferred.promise

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

    @get_subscribers: (trigger_point) ->
      key = @_trigger_key(trigger_point)
      bucket.get(key)
      .then (d) ->
        return new Error("There isn't any subscriber for trigger point: #{trigger_point}") if d instanceof Error or d.value.subscribers.length is 0
        d.value.subscribers

    @render_emails_data: (trigger_event, data, emails) ->
      template = Path.join options.root, options.trigger_events[trigger_event].template
      html = jade.renderFile template, _.extend({}, data, { base: options.url, scheme: options.scheme } )
      subject = options.trigger_events[trigger_event].subject
      emails_data = []
      _.each emails, (email) ->
        emails_data.push(
          from: options.from
          to: email
          subject: subject
          html: html
        )
      Q emails_data

    @_trigger_key: (trigger_point) ->
      "#{Trigger::PREFIX}:#{trigger_point}"

    @_unsubscribe_key: (email) ->
      "#{Trigger::PREFIX}:#{email}:#{Trigger::POSTFIX}"