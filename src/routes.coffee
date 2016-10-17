TriggerValidator = require './models/triggerValidator'

module.exports = (server, options) ->

  Trigger = require('./handlers/trigger') server, options

  [
    {
      method: "POST"
      path: "/v1/trigger/{trigger_key}/subscribe"
      config:
        handler: Trigger.subscribe
        validate: TriggerValidator::subscribe
        description: "Subscribes a list of emails to a trigger key"
        label: ['email']
    }
    {
      method: "POST"
      path: "/v1/trigger/{trigger_key}/post"
      config:
        handler: Trigger.post
        validate: TriggerValidator::post
        description: "Posts an email to addresses of a trigger point"
        label: ["email"]
    }
    {
      method: "POST"
      path: "/v1/email/{email}/unsubscribe"
      config:
        handler: Trigger.unsubscribe
        validate: TriggerValidator::unsubscribe
        description: "Unsubscribes an email from a list of trigger keys"
        label: ["email"]
    }
  ]
