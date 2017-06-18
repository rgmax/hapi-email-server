_ = require "lodash"
Q = require "q"
jade = require 'jade'
Path = require 'path'
fs = require 'fs-extra'
moment = require 'moment'

module.exports = (server, options) ->

  bucket   = options.database
  mailgun  = require('mailgun-js') { apiKey: options.config.api_key, domain: options.config.domain }
  mandrill = require('mandrill-api/mandrill')

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

    @post: (trigger_point, data, emails) ->
      _this = @
      system = if data.meta?.system? then data.meta.system else null
      @get_trigger_event(trigger_point)
      .then (trigger_event) ->
        return trigger_event if trigger_event instanceof Error
        if emails?
          promises = []
          subscribed_emails = []
          _.each emails, (email) ->
            promises.push(
              _this.check_if_email_unsubscribed(email, trigger_point)
              .then (unsubscribed) ->
                subscribed_emails.push email unless unsubscribed
            )
          Q.all(promises)
          .then ->
            return new Error("All emails have un-subscribed from trigger point: #{trigger_point}") if subscribed_emails.length is 0
            switch system
              when 'mandrill'
                _this.mandrill_send(data, subscribed_emails)
              else
                _this.mailgun_send_to_emails(trigger_event, data, subscribed_emails)
        else
          switch system
            when 'mandrill'
              _this.get_subscribers(trigger_point)
                .then (emails) ->
                  return emails if emails instanceof Error
                  _this.mandrill_sent(data, emails)
            else
              _this.mailgun_send_to_subscribers(trigger_point, trigger_event, data)

    @mandrill_send: (data, emails) ->
      deferred = Q.defer()
      mandrill_client = new mandrill.Mandrill(data.meta.mandrill.apiKey)
      message = {
        subject: data.meta.mandrill.subject
        from_email: data.meta.mandrill.from_email
        from_name: data.meta.mandrill.from_name
        to: []
        merge: true
        merge_language: 'mailchimp'
        global_merge_vars: []
      }
      _.each data.meta.mandrill.global_merge_var_names, (name) ->
        message.global_merge_vars.push( { name, content: data[name] } )
      _.each emails, (email) ->
        message.to.push({ email })
      async = false
      send_at = moment().subtract(1, 'd').format('YYYY-MM-DD')
      mandrill_client.messages.sendTemplate { template_name: data.meta.mandrill.template, template_content: [{}], message, async, send_at },
        (result) ->
          console.log(result)
          deferred.resolve true
        (e) ->
          console.log('A mandrill error occurred: ' + e.name + ' - ' + e.message)
          deferred.resolve new Error e.message
      deferred.promise



    @mailgun_send_to_emails: (trigger_event, data, subscribed_emails) ->
      _this = @
      _this.render_emails_data(trigger_event, data, subscribed_emails)
        .then (emails_data) ->
          promises = []
          _.each emails_data, (email_data) ->
            promises.push _this.send(email_data)
          Q.all(promises)

    @mailgun_send_to_subscribers: (trigger_point, trigger_event, data) ->
      _this = @
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
      if options.config.mock
        if options.config.trace
          console.log "From: #{email_data.from}"
          console.log "To: #{email_data.to}"
          console.log "Subject: #{email_data.subject}"
          console.log email_data.html
        if options.config.dump
          file = Path.join options.config.dump_path, "#{email_data.to}_#{email_data.subject}.html"
          @dir_ensure(file)
          .then (err) ->
            fs.writeFile file, email_data.html, (error) ->
              if error
                deferred.resolve new Error error
              else
                deferred.resolve file
        else
          deferred.resolve true
      else
        mailgun.messages().send email_data,
          (error, body) ->
            if error
              deferred.resolve new Error error
            else
              deferred.resolve body
      deferred.promise

    @check_if_email_unsubscribed: (email, trigger_point) ->
      @get_email_unsubscribes(email)
      .then (trigger_points) ->
        return true if trigger_points.indexOf(trigger_point) >= 0
        false

    @get_email_unsubscribes: (email) ->
      key = @_unsubscribe_key(email)
      bucket.get(key)
      .then (d) ->
        return [] if d instanceof Error
        d.value.trigger_points

    @unsubscribe: (email, trigger_points) ->
      return @delete_all_unsubscribe(email) if trigger_points.length is 0
      key = @_unsubscribe_key(email)
      _this = @
      promises = []
      _.each trigger_points, (trigger_point) ->
        promises.push _this.get_trigger_event(trigger_point)
      Q.all(promises)
      .then (results) ->
        error_found = false
        _.each results, (result) ->
          error_found = true if result instanceof Error
        return new Error('List contains unknown trigger events.') if error_found
        doc = { trigger_points: trigger_points }
        bucket.get(key)
        .then (d) ->
          if d instanceof Error
            bucket.insert(key, doc)
          else
            bucket.replace(key, doc)

    @delete_all_unsubscribe: (email) ->
      key = @_unsubscribe_key(email)
      doc = { trigger_points: [] }
      bucket.get(key)
      .then (d) ->
        if d instanceof Error
          bucket.insert(key, doc)
        else
          bucket.replace(key, doc)

    @get_trigger_event: (trigger_point) ->
      parts = trigger_point.split(":")
      trigger_event = parts[ parts.length - 1 ]
      trigger_events = _.keys options.config.trigger_events
      return Q( new Error("Trigger event '#{trigger_event}' is not defined!") ) if trigger_events.indexOf(trigger_event) < 0
      Q trigger_event

    @get_subscribers: (trigger_point) ->
      key = @_trigger_key(trigger_point)
      bucket.get(key)
      .then (d) ->
        return new Error("There isn't any subscriber for trigger point: #{trigger_point}") if d instanceof Error or d.value.subscribers.length is 0
        d.value.subscribers

    @delete_all_subscribers: (trigger_point) ->
      _this = @
      @get_trigger_event(trigger_point)
      .then (trigger_event) ->
        return trigger_event if trigger_event instanceof Error
        trigger_key = _this._trigger_key(trigger_point)
        doc = { subscribers: [] }
        bucket.get(trigger_key)
        .then (d) ->
          if d instanceof Error
            bucket.insert(trigger_key, doc)
          else
            bucket.replace(trigger_key, doc)

    @render_emails_data: (trigger_event, data, emails) ->
      set_template = (data) =>
        config_template = Path.join options.config.root, options.config.trigger_events[trigger_event].template
        return Q(config_template) unless data.meta?.template?
        payload_template = Path.join options.config.root, data.meta.template
        @path_exists(payload_template)
        .then (err) ->
          return Q(config_template) if err
          Q(payload_template)
      set_template(data)
      .then (template) ->
        html = jade.renderFile template, _.extend({}, data, { base: options.url, scheme: options.scheme } )
        subject = if data.meta?.subject? then data.meta.subject else options.config.trigger_events[trigger_event].subject
        emails_data = []
        _.each emails, (email) ->
          email_data =
            from: options.config.from
            to: email
            subject: subject
            html: html
          if data.attachment?
            if typeof data.attachment is 'object'
              email_data.attachment =  new mailgun.Attachment data.attachment
            else
              email_data.attachment = data.attachment
          emails_data.push email_data
        Q emails_data

    @_trigger_key: (trigger_point) ->
      "#{Trigger::PREFIX}:#{trigger_point}"

    @_unsubscribe_key: (email) ->
      "#{Trigger::PREFIX}:#{email}:#{Trigger::POSTFIX}"

    @dir_ensure: (path) ->
      deferred = Q.defer()
      fs.ensureDir Path.dirname(path), (err) ->
        deferred.resolve()
      deferred.promise

    @path_exists: (path) ->
      deferred = Q.defer()
      fs.access path, fs.F_OK | fs.R_OK, (err) ->
        deferred.resolve(err)
      deferred.promise

    @validate_mandrill_apiKey: (apiKey) ->
      deferred = Q.defer()
      mandrill_client = new mandrill.Mandrill apiKey
      mandrill_client.users.ping2 {},
        (result) ->
          if result.PING? && result.PING == 'PONG!'
            deferred.resolve(true)
          else
            deferred.resolve(false)
        (e) ->
          deferred.resolve(false)
      deferred.promise