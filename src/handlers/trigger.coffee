module.exports = (server, options) ->
  {
    trigger:
      subscribe: (request, reply) ->
        reply.success(true)

      post: (request, reply) ->
        reply.success(true)

      unsubscribe: (request, reply) ->
        reply.success(true)
  }