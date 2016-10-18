module.exports = (server, options) ->

  Trigger = require("../models/trigger") server, options

  {
    subscribe: (request, reply) ->
      trigger_point = request.params.trigger_point
      emails = request.payload.emails
      Trigger.subscribe(trigger_point, emails)
      .then (result) ->
        return reply.fail(result.message) if result instanceof Error
        reply.success(true)

    post: (request, reply) ->
      trigger_point = request.params.trigger_point
      data = request.payload.data
      email = request.payload.email
      Trigger.post(trigger_point, data, email)
      .then (result) ->
        return reply.fail(result.message) if result instanceof Error
        reply.success(true)

    unsubscribe: (request, reply) ->
      email = request.params.email
      trigger_points = request.payload.trigger_points
      Trigger.unsubscribe(email, trigger_points)
      .then (result) ->
        return reply.fail(result.message) if result instanceof Error
        reply.success(true)

    unsubscribe_list: (request, reply) ->
      email = request.params.email
      Trigger.get_email_unsubscribes(email)
      .then (result) ->
        return reply.fail(result.message) if result instanceof Error
        reply.nice { list: result, total: result.length }
  }