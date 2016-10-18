(function() {
  var TriggerValidator;

  TriggerValidator = require('./models/triggerValidator');

  module.exports = function(server, options) {
    var Trigger;
    Trigger = require('./handlers/trigger')(server, options);
    return [
      {
        method: "POST",
        path: "/v1/trigger/{trigger_point}/subscribe",
        config: {
          handler: Trigger.trigger.subscribe,
          validate: TriggerValidator.prototype.subscribe,
          description: "Subscribes a list of emails to a trigger point",
          tags: ["email"]
        }
      }, {
        method: "POST",
        path: "/v1/trigger/{trigger_point}/post",
        config: {
          handler: Trigger.trigger.post,
          validate: TriggerValidator.prototype.post,
          description: "Posts an email to addresses of a trigger point",
          tags: ["email"]
        }
      }, {
        method: "POST",
        path: "/v1/email/{email}/unsubscribe",
        config: {
          handler: Trigger.trigger.unsubscribe,
          validate: TriggerValidator.prototype.unsubscribe,
          description: "Unsubscribes an email from a list of trigger points",
          tags: ["email"]
        }
      }
    ];
  };

}).call(this);
