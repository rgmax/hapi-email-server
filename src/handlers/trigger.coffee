module.exports = (server, options) ->

  Trigger = require("../models/trigger") server, options

  {
    trigger:
      subscribe: (request, reply) ->
        trigger_key = request.params.trigger_key
        emails = request.payload.emails
        Trigger.subscribe(trigger_key, emails)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(true)

      post: (request, reply) ->
        trigger_key = request.params.trigger_key
        data = request.payload.data
        email = request.payload.email
        Trigger.post(trigger_key, data, email)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(true)

      unsubscribe: (request, reply) ->
        email = request.params.email
        triggers = request.payload.triggers
        Trigger.unsubscribe(email, triggers)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(true)
  }