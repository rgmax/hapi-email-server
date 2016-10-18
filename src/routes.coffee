TriggerValidator = require './models/triggerValidator'

module.exports = (server, options) ->

  Trigger = require('./handlers/trigger') server, options

  [
    {
      method: "POST"
      path: "/v1/trigger/{trigger_point}/subscribe"
      config:
        handler: Trigger.trigger.subscribe
        validate: TriggerValidator::subscribe
        description: "Subscribes a list of emails to a trigger point"
        label: ['email']
    }
    {
      method: "POST"
      path: "/v1/trigger/{trigger_point}/post"
      config:
        handler: Trigger.trigger.post
        validate: TriggerValidator::post
        description: "Posts an email to addresses of a trigger point"
        label: ["email"]
    }
    {
      method: "POST"
      path: "/v1/email/{email}/unsubscribe"
      config:
        handler: Trigger.trigger.unsubscribe
        validate: TriggerValidator::unsubscribe
        description: "Unsubscribes an email from a list of trigger points"
        label: ["email"]
    }
  ]
