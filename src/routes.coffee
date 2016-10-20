TriggerValidator = require './models/triggerValidator'

module.exports = (server, options) ->

  Trigger = require('./handlers/trigger') server, options

  [
    {
      method: "POST"
      path: "/v1/triggers/{trigger_point}/subscribe"
      config:
        handler: Trigger.subscribe
        validate: TriggerValidator::subscribe
        description: "Subscribes a list of emails to a trigger point"
        tags: ["email"]
    }
    {
      method: "DELETE"
      path: "/v1/triggers/{trigger_point}/subscribers"
      config:
        handler: Trigger.delete_all_subscribers
        validate: TriggerValidator::delete_all_subscribers
        description: "Deletes all subscribed emails of a trigger point"
        tags: ["email"]
    }
    {
      method: "GET"
      path: "/v1/triggers/{trigger_point}/subscribers"
      config:
        handler: Trigger.subscribers
        validate: TriggerValidator::subscribers
        description: "Gets a list of subscribed emails for a trigger point"
        tags: ["email"]
    }
    {
      method: "POST"
      path: "/v1/triggers/{trigger_point}/post"
      config:
        handler: Trigger.post
        validate: TriggerValidator::post
        description: "Posts an email to addresses of a trigger point"
        tags: ["email"]
    }
    {
      method: "POST"
      path: "/v1/emails/{email}/unsubscribe"
      config:
        handler: Trigger.unsubscribe
        validate: TriggerValidator::unsubscribe
        description: "Unsubscribes an email from a list of trigger points"
        tags: ["email"]
    }
    {
      method: "GET"
      path: "/v1/emails/{email}/unsubscribe_list"
      config:
        handler: Trigger.unsubscribe_list
        validate: TriggerValidator::unsubscribe_list
        description: "Gets a list of unsubscribed trigger points for an email"
        tags: ["email"]
    }
  ]
