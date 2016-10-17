module.exports = (server, options) ->

  return class Trigger

    @subscribe: (trigger_key, emails) ->
      new Error("Not implemented yet!")

    @post: (trigger_key, data, email) ->
      new Error("Not implemented yet!")

    @unsubscribe: (email, triggers) ->
      new Error("Not implemented yet!")