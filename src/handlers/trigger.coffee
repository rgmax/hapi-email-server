module.exports = (server, options) ->

  Trigger = require("../models/trigger") server, options

  {
    trigger:
      subscribe: (request, reply) ->
        trigger_point = request.params.trigger_point
        emails = request.payload.emails
        Trigger.subscribe(trigger_point, emails)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(result)

      post: (request, reply) ->
        trigger_point = request.params.trigger_point
        data = request.payload.data
        email = request.payload.email
        Trigger.post(trigger_point, data, email)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(result)

      unsubscribe: (request, reply) ->
        email = request.params.email
        trigger_points = request.payload.trigger_points
        Trigger.unsubscribe(email, trigger_points)
        .then (result) ->
          return reply.fail(result.message) if result instanceof Error
          reply.success(result)
  }